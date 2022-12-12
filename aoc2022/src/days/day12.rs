use std::collections::{BinaryHeap, HashMap, HashSet};

use crate::problem::Problem;

pub struct Solution {}

const OFFSETS: [(isize, isize); 4] = [(1, 0), (0, -1), (-1, 0), (0, 1)];

type Vertex = (isize, isize);

struct Environment {
    cost_map: HashMap<Vertex, usize>,
    start: Vertex,
    end: Vertex,
    width: usize,
    height: usize,
}

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
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Eq for Visit {}

impl Ord for Visit {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        other.dist.cmp(&self.dist)
    }
}

fn in_bounds(p: Vertex, width: isize, height: isize) -> bool {
    p.0 >= 0 && p.1 >= 0 && p.0 < width && p.1 < height
}

fn get_neighbors(center: &Vertex, width: isize, height: isize) -> Vec<Vertex> {
    OFFSETS
        .iter()
        .map(|&(x, y)| (center.0 + x, center.1 + y))
        .filter(|p| in_bounds(*p, width, height))
        .collect()
}

fn parse_input(input: &str) -> Environment {
    let mut cost_map = HashMap::new();
    let mut start = (0, 0);
    let mut end = (0, 0);
    let height = input.lines().count();
    let width = input.lines().next().unwrap().chars().count();

    for (y, row) in input.lines().enumerate() {
        for (x, c) in row.chars().enumerate() {
            let (x, y) = (x as isize, y as isize);

            let cost = match c {
                'S' => {
                    start = (x, y);
                    'a'
                }
                'E' => {
                    end = (x, y);
                    'z'
                }
                _ => c,
            } as usize
                - 'a' as usize;

            cost_map.insert((x, y), cost);
        }
    }

    Environment {
        cost_map,
        start,
        end,
        width,
        height,
    }
}

fn create_adj_list(
    points: &HashMap<Vertex, usize>,
    size: (usize, usize),
    steps: bool,
) -> HashMap<Vertex, Vec<(Vertex, usize)>> {
    let can_traverse = |start, end| end <= start + 1;

    points
        .iter()
        .map(|(&vert, cost)| {
            (
                vert,
                get_neighbors(&vert, size.0 as isize, size.1 as isize)
                    .iter()
                    .map(|n| (*n, *points.get(n).unwrap()))
                    .filter(|(_, c)| can_traverse(*cost as isize, *c as isize))
                    .map(|(k, c)| if steps { (k, 1) } else { (k, c) })
                    .collect::<Vec<(Vertex, usize)>>(),
            )
        })
        .collect::<HashMap<Vertex, Vec<(Vertex, usize)>>>()
}

fn dijkstras(
    starts: Vec<Vertex>,
    adj_list: &HashMap<Vertex, Vec<(Vertex, usize)>>,
) -> HashMap<Vertex, usize> {
    let mut visited = HashSet::new();
    let mut distances = HashMap::new();
    let mut to_visit = BinaryHeap::new();

    starts.iter().for_each(|&start| {
        distances.insert(start, 0);
        to_visit.push(Visit {
            vertex: start,
            dist: 0,
        });
    });

    while let Some(Visit { vertex, dist }) = to_visit.pop() {
        if !visited.insert(vertex) {
            continue;
        }

        if let Some(neighbors) = adj_list.get(&vertex) {
            for (neighbor, cost) in neighbors {
                let new_distance = dist + cost;
                let is_shorter = distances.get(neighbor).map_or(true, |&d| new_distance < d);
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

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let goal = parse_input(_input);
        let adj_list = create_adj_list(&goal.cost_map, (goal.width, goal.height), true);
        let distances = dijkstras(vec![goal.start], &adj_list);
        let answer = *distances.get(&goal.end).unwrap();

        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let goal = parse_input(_input);
        let adj_list = create_adj_list(&goal.cost_map, (goal.width, goal.height), true);
        let starts = goal
            .cost_map
            .iter()
            .filter(|(_, &v)| v == 0)
            .map(|(&k, _)| k)
            .collect::<Vec<Vertex>>();
        let distances = dijkstras(starts, &adj_list);
        let answer = *distances.get(&goal.end).unwrap();

        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "Sabqponm
abcryxxl
accszExk
acctuvwj
abdefghi";

    #[test]
    fn test_day12a() {
        let solver = Solution {};
        assert_eq!(solver.part1(INPUT).unwrap(), "31");
    }

    #[test]
    fn test_day12b() {
        let solver = Solution {};
        assert_eq!(solver.part2(INPUT).unwrap(), "29");
    }
}
