use std::{
    collections::HashMap,
};

use crate::problem::Problem;

pub struct Solution {}

type Point = (isize, isize);

struct Line(Vec<Point>);

impl Line {
    fn from_input(input: &str) -> Self {
        let out = input
            .split(" -> ")
            .map(|p| match p.split_once(',') {
                Some((x, y)) => (x.parse().unwrap(), y.parse().unwrap()),
                None => panic!("Failed interpreting line."),
            })
            .collect::<Vec<Point>>();
        Line(out)
    }

    fn points(&self) -> Vec<Point> {
        let (mut sx, mut sy) = self.0[0];
        self.0
            .iter()
            .skip(1)
            .flat_map(|(x, y)| {
                let (dx, dy) = (x - sx, y - sy);
                let out = if dx == 0 {
                    if dy < 0 {
                        (sy + dy..=sy).map(|_y| (sx, _y)).collect::<Vec<Point>>()
                    } else {
                        (sy..=sy + dy).map(|_y| (sx, _y)).collect::<Vec<Point>>()
                    }
                } else {
                    if dx < 0 {
                        (sx + dx..=sx).map(|_x| (_x, sy)).collect::<Vec<Point>>()
                    } else {
                        (sx..=sx + dx).map(|_x| (_x, sy)).collect::<Vec<Point>>()
                    }
                };
                (sx, sy) = (*x, *y);
                out
            })
            .collect::<Vec<Point>>()
    }
}

fn create_walls(input: &str) -> HashMap<Point, char> {
    let mut blocks: HashMap<Point, char> = HashMap::new();

    input.lines().for_each(|l| {
        Line::from_input(l)
            .points()
            .iter()
            .for_each(|p| *blocks.entry(*p).or_insert('#') = '#')
    });

    blocks
}

fn drop_sand(
    blocks: &mut HashMap<Point, char>,
    start: Point,
    abyss_level: isize,
    abyss_is_floor: bool,
) -> (Point, bool) {
    let (mut x, mut y) = start;

    while y <= abyss_level {
        let next = match blocks.get(&(x, y + 1)) {
            Some(_) => match blocks.get(&(x - 1, y + 1)) {
                Some(_) => match blocks.get(&(x + 1, y + 1)) {
                    Some(_) => (x, y),
                    None => (x + 1, y + 1),
                },
                None => (x - 1, y + 1),
            },
            None => (x, y + 1),
        };
        if next == (x, y) {
            blocks.insert((x, y), 'o');
            return ((x, y), true);
        }

        (x, y) = next;
    }

    if abyss_is_floor {
        blocks.insert((x, y), 'o');
    }

    ((x, y), false)
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let mut blocks = create_walls(_input);
        let abyss_level = blocks.keys().map(|(_, y)| *y).max().unwrap() + 1;
        let mut n_blocks = 0;
        while drop_sand(&mut blocks, (500, 0), abyss_level, false).1 {
            n_blocks += 1;
        }

        Some(n_blocks.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let mut blocks = create_walls(_input);
        let abyss_level = blocks.keys().map(|(_, y)| *y).max().unwrap() + 0;
        let mut n_blocks = 0;
        loop {
            let (p, _) = drop_sand(&mut blocks, (500, 0), abyss_level, true);
            n_blocks += 1;
            if p == (500, 0) {
                break;
            }
        }

        Some(n_blocks.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "498,4 -> 498,6 -> 496,6
503,4 -> 502,4 -> 502,9 -> 494,9";

    #[test]
    fn test_day14a() {
        let solution = Solution {};
        let answer = solution.part1(INPUT).unwrap();
        assert_eq!(answer, "24");
    }

    #[test]
    fn test_day14b() {
        let solution = Solution {};
        let answer = solution.part2(INPUT).unwrap();
        assert_eq!(answer, "93");
    }
}
