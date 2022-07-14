use crate::problem::Problem;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet};
use std::fmt;
use std::ops::Add;

pub struct Solution {}

#[derive(Eq, Hash, Copy, Clone)]
struct Point {
    x: isize,
    y: isize,
}

impl fmt::Debug for Point {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

impl Add for Point {
    type Output = Self;
    fn add(self, other: Self) -> Self {
        Self {
            x: self.x + other.x,
            y: self.y + other.y,
        }
    }
}

impl PartialEq for Point {
    fn eq(&self, other: &Self) -> bool {
        self.x == other.x && self.y == other.y
    }
}

#[derive(Hash, Eq, PartialEq, Copy, Clone)]
struct Vertex {
    point: Point,
}

impl fmt::Debug for Vertex {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {})", self.point.x, self.point.y)
    }
}

impl Vertex {
    fn from_xy(x: isize, y: isize) -> Vertex {
        Vertex {
            point: Point { x: x, y: y },
        }
    }
    fn from_point(point: Point) -> Vertex {
        Vertex { point }
    }
}

#[derive(Hash)]
struct Visit {
    vertex: Vertex,
    dist: usize,
}

impl PartialEq for Visit {
    fn eq(&self, other: &Self) -> bool {
        self.dist.eq(&other.dist)
    }
}

impl PartialOrd for Visit {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Visit {
    fn cmp(&self, other: &Self) -> Ordering {
        other.dist.cmp(&self.dist)
    }
}

impl Eq for Visit {}

const OFFSETS: [(isize, isize); 4] = [(1, 0), (0, -1), (-1, 0), (0, 1)];

fn in_bounds(p: Point, width: isize, height: isize) -> bool {
    p.x >= 0 && p.y >= 0 && p.x < width && p.y < height
}

fn get_neighbors(center: Point, width: isize, height: isize) -> Vec<Point> {
    OFFSETS
        .iter()
        .map(|&(x, y)| center + Point { x: x, y: y })
        .filter(|p| in_bounds(*p, width, height))
        .collect()
}

fn parse_tiled_point_costs(
    input: &str,
    size: (usize, usize),
    repeats: (usize, usize),
) -> HashMap<Point, usize> {
    let (tw, th) = repeats;

    let new_input: Vec<String> = input
        .repeat(th)
        .lines()
        .map(|l| l.repeat(tw))
        .collect();

    new_input
        .iter()
        .enumerate()
        .flat_map(|(y, row)| {
            row.chars().enumerate().map(move |(x, c)| {
                let cost = c as usize - 0x30;
                let tx = x / size.0;
                let ty = y / size.1;
                (
                    Point {
                        x: x as isize,
                        y: y as isize,
                    },
                    ((cost + tx + ty - 1) % 9) + 1,
                )
            })
        })
        .collect::<HashMap<Point, usize>>()
}

fn create_adj_list(
    points: &HashMap<Point, usize>,
    size: (usize, usize),
) -> HashMap<Vertex, Vec<(Vertex, usize)>> {
    // Constuct adj list
    points
        .iter()
        .map(|(&point, _)| {
            (
                Vertex::from_point(point),
                get_neighbors(point, size.0 as isize, size.1 as isize)
                    .iter()
                    .map(|n| {
                        let c = *points.get(n).unwrap();
                        (Vertex::from_point(*n), c)
                    })
                    .collect(),
            )
        })
        .collect::<HashMap<Vertex, Vec<(Vertex, usize)>>>()
}

fn dijkstras(
    start: Vertex,
    adj_list: &HashMap<Vertex, Vec<(Vertex, usize)>>,
) -> HashMap<Vertex, usize> {
    let mut visited = HashSet::new();
    let mut distances = HashMap::new();
    let mut to_visit = BinaryHeap::new();

    distances.insert(start, 0);
    to_visit.push(Visit {
        vertex: start,
        dist: 0,
    });

    while let Some(Visit { vertex, dist }) = to_visit.pop() {
        if !visited.insert(vertex) {
            continue;
        }

        if let Some(neighbors) = adj_list.get(&vertex) {
            for (neighbor, cost) in neighbors {
                let new_distance = dist + cost;
                let is_shorter = distances.get(&neighbor).map_or(true, |&d| new_distance < d);
                if is_shorter {
                    distances.insert(*neighbor, new_distance);
                    to_visit.push(Visit {
                        vertex: *neighbor,
                        dist: new_distance,
                    });
                }
            }
        }
    }

    distances
}

fn find_risk(input: &str, size: (usize, usize), repeats: (usize, usize)) -> usize {
    let point_cost_map = parse_tiled_point_costs(input, size, repeats);
    let adj_map = create_adj_list(&point_cost_map, (size.0 * repeats.0, size.1 * repeats.1));
    let start = Vertex::from_xy(0, 0);
    let end = Vertex::from_xy(
        (repeats.0 * size.0 - 1) as isize,
        (repeats.1 * size.1 - 1) as isize,
    );
    let distances = dijkstras(start, &adj_map);
    distances[&end]
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let risk = find_risk(input, (100, 100), (1, 1));
        format!("{}", risk)
    }

    fn part2(&self, input: &str) -> String {
        let risk = find_risk(input, (100, 100), (5, 5));
        format!("{}", risk)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "1163751742
1381373672
2136511328
3694931569
7463417111
1319128137
1359912421
3125421639
1293138521
2311944581";

        let risk = find_risk(input, (10, 10), (1, 1));
        assert_eq!(risk, 40);
    }

    #[test]
    fn test_part2_example() {
        let input = "1163751742
1381373672
2136511328
3694931569
7463417111
1319128137
1359912421
3125421639
1293138521
2311944581\n";

        let risk = find_risk(input, (10, 10), (5, 5));
        assert_eq!(risk, 315);
    }
}
