use crate::problem::Problem;
use disjoint_sets::UnionFind;

pub struct Solution {}

type Matrix = Vec<Vec<u32>>;
type Point = (usize, usize);

fn parse_input(input: &str) -> Matrix {
    input
        .lines()
        .map(|l| {
            l.chars()
                .map(|c| c.to_digit(10).unwrap())
                .collect::<Vec<u32>>()
        })
        .collect()
}

// Part 1
fn get_neighbors(matrix: &Matrix, point: Point) -> Vec<(Point, u32)> {
    let offsets: Vec<(i32, i32)> = vec![(1, 0), (0, 1), (-1, 0), (0, -1)];
    let height = matrix.len() as i32;
    let width = matrix[0].len() as i32;
    let (x, y) = point;
    offsets
        .iter()
        .map(|(ox, oy)| ((x as i32) + ox, (y as i32) + oy))
        .filter(|&(nx, ny)| ny >= 0 && ny < height && nx >= 0 && nx < width)
        .map(|(nx, ny)| ((nx as usize, ny as usize), matrix[ny as usize][nx as usize]))
        .collect()
}

fn is_minima(matrix: &Matrix, point: Point) -> bool {
    let neighbors = get_neighbors(matrix, point);
    let curr_depth = matrix[point.1][point.0];
    neighbors
        .iter()
        .fold(true, |acc, (_, depth)| acc && depth > &curr_depth)
}

fn find_minima_values(matrix: &Matrix) -> Vec<u32> {
    matrix
        .iter()
        .enumerate()
        .map(|(y, row)| row.iter().enumerate().map(move |(x, val)| (val, (x, y))))
        .flatten()
        .filter(|(_, p)| is_minima(matrix, *p))
        .map(|(&d, _)| d)
        .collect::<Vec<u32>>()
}

// Part 2
fn two_pass(matrix: &Matrix) -> Vec<usize> {
    /// Uses a two pass connected component algorithm. 

    let mut current_label: usize = 1;
    let mut basin_sizes = vec![0];
    let height = matrix.len();
    let width = matrix[0].len();
    let mut equiv = UnionFind::<usize>::new(2000); // Don't hardcode size?
    let mut labels: Vec<Vec<usize>> = Vec::new();
    for _ in 0..height {
        labels.push(vec![0;width]);
    }

    // Label regions
    for y in 0..height {
        for x in 0..width {
            let west_not_peak = if x == 0 { false } else { matrix[y][x - 1] != 9 };
            let west_label = if x == 0 { 0 } else { labels[y][x - 1] };
            let north_not_peak = if y == 0 { false } else { matrix[y - 1][x] != 9 };
            let north_label = if y == 0 { 0 } else { labels[y - 1][x] };

            if matrix[y][x] == 9 {
                // Peaks are labeled 0
                labels[y][x] = 0;
            } else {
                labels[y][x] = match (west_not_peak, north_not_peak, west_label == north_label) {
                    (false, false, _) => {
                        current_label += 1;
                        basin_sizes.push(0);
                        current_label - 1
                    },
                    (true, false, _) => labels[y][x-1],
                    (false, true, _) => labels[y-1][x],
                    (true, true, true) => labels[y][x-1],
                    (true, true, false) => {
                        equiv.union(west_label, north_label);
                        labels[y][x-1]
                    },
                };
            }
        }
    }

    // Rename regions based on equivalency
    for y in 0..height {
        for x in 0..width {
            labels[y][x] = equiv.find(labels[y][x]);
            basin_sizes[labels[y][x]] += 1;
        }
    }

    basin_sizes.remove(0);
    basin_sizes
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let matrix = parse_input(input);
        let solution: u32 = find_minima_values(&matrix)
            .iter()
            .fold(0, |acc, n| acc + 1 + n);
        format!("{}", solution)
    }

    fn part2(&self, input: &str) -> String {
        let matrix = parse_input(input);
        let mut solution = two_pass(&matrix);
        solution.sort_unstable();

        let answer = solution.iter().rev().take(3).fold(1, |acc, val| acc * val);

        format!("{:?}", answer) 
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "2199943210
3987894921
9856789892
8767896789
9899965678";

        let matrix = parse_input(input);
        let solution = find_minima_values(&matrix)
            .iter()
            .fold(0, |acc, n| acc + 1 + n);
        dbg!(solution);
        assert_eq!(solution, 15);
    }
    #[test]
    fn test_part2_example() {
        let input = "2199943210
3987894921
9856789892
8767896789
9899965678";
        let matrix = parse_input(input);
        let mut solution = two_pass(&matrix);
        solution.sort_unstable();

        dbg!(&solution);
        let answer = solution.iter().rev().take(3).fold(1, |acc, val| acc * val);
        assert_eq!(answer, 1134);
        
    }
}
