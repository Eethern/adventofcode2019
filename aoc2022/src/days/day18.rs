use std::collections::{HashSet, VecDeque};

use itertools::Itertools;

use crate::problem::Problem;

pub struct Solution {}

type Cube = (i32, i32, i32);

fn parse_input(input: &str) -> Vec<Cube> {
    input
        .lines()
        .map(|l| {
            l.split(',')
                .map(|c| c.parse::<i32>().unwrap())
                .collect_tuple()
                .unwrap()
        })
        .collect::<Vec<Cube>>()
}

fn get_dimensions(cubes: &Vec<Cube>) -> (usize, usize, usize) {
    let dim_x = (cubes.iter().map(|c| c.0).max().unwrap() + 3) as usize;
    let dim_y = (cubes.iter().map(|c| c.1).max().unwrap() + 3) as usize;
    let dim_z = (cubes.iter().map(|c| c.2).max().unwrap() + 3) as usize;

    (dim_x, dim_y, dim_z)
}

fn to_grid(cubes: &Vec<Cube>, dimensions: (usize, usize, usize)) -> Vec<Vec<Vec<i32>>> {
    let (dim_x, dim_y, dim_z) = dimensions;
    let mut grid = vec![vec![vec![0; dim_z]; dim_y]; dim_x];
    cubes
        .iter()
        .for_each(|(x, y, z)| grid[(x + 1) as usize][(y + 1) as usize][(z + 1) as usize] = 1);
    grid
}

fn count_surfaces(cubes: &Vec<(i32, i32, i32)>, grid: &Vec<Vec<Vec<i32>>>) -> usize {
    cubes.iter().fold(0, |acc, (x, y, z)| {
        acc + NEIGHBORHOOD.iter().fold(0, |a, (ox, oy, oz)| {
            a + 1 - grid[(x + 1 + ox) as usize][(y + 1 + oy) as usize][(z + 1 + oz) as usize]
        })
    }) as usize
}

fn flood_fill(grid: &Vec<Vec<Vec<i32>>>, dimensions: (usize, usize, usize)) -> usize {
    let (dim_x, dim_y, dim_z) = dimensions;
    let mut q = VecDeque::new();
    let mut visited = HashSet::new();
    let mut num_surfaces = 0;
    // Push start
    q.push_back((0, 0, 0));

    while let Some(p) = q.pop_front() {
        visited.insert(p);

        let (x, y, z) = p;
        NEIGHBORHOOD.iter().for_each(|(ox, oy, oz)| {
            let (_x, _y, _z) = (x + ox, y + oy, z + oz);
            if !visited.contains(&(_x, _y, _z)) && !q.contains(&(_x, _y, _z)) {
                if _x >= 0
                    && _x < (dim_x as i32)
                    && _y >= 0
                    && _y < (dim_y as i32)
                    && _z >= 0
                    && _z < (dim_z as i32)
                {
                    if grid[_x as usize][_y as usize][_z as usize] == 0 {
                        q.push_front((_x, _y, _z));
                    } else {
                        num_surfaces += 1;
                    }
                }
            }
        })
    }
    num_surfaces
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let cubes = parse_input(_input);

        let (dim_x, dim_y, dim_z) = get_dimensions(&cubes);

        let grid = to_grid(&cubes, (dim_x, dim_y, dim_z));
        let num_surfaces = count_surfaces(&cubes, &grid);

        Some(num_surfaces.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let cubes = parse_input(_input);
        let (dim_x, dim_y, dim_z) = get_dimensions(&cubes);
        let grid = to_grid(&cubes, (dim_x, dim_y, dim_z));

        let n_surfaces = flood_fill(&grid, (dim_x, dim_y, dim_z));

        Some(n_surfaces.to_string())
    }
}

const NEIGHBORHOOD: [(i32, i32, i32); 6] = [
    (0, 0, 1),
    (0, 1, 0),
    (1, 0, 0),
    (0, 0, -1),
    (0, -1, 0),
    (-1, 0, 0),
];

#[cfg(test)]
mod tests {
    use super::*;

    // const INPUT: &str = "1,1,1\n2,1,1";

    const INPUT: &str = "2,2,2
1,2,2
3,2,2
2,1,2
2,3,2
2,2,1
2,2,3
2,2,4
2,2,6
1,2,5
3,2,5
2,1,5
2,3,5
";

    #[test]
    fn test_day18a() {
        let solution = Solution {};
        let answer = solution.part1(INPUT).unwrap();
        assert_eq!(answer, "64");
    }

    #[test]
    fn test_day18b() {
        let solution = Solution {};
        let answer = solution.part2(INPUT).unwrap();
        assert_eq!(answer, "58");
    }
}
