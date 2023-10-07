use std::collections::HashMap;

use regex::Regex;

use crate::problem::Problem;

pub struct Solution {}

#[derive(Debug, PartialEq)]
enum Tile {
    Portal,
    Wall,
    Floor,
}

#[derive(Debug)]
enum Action {
    Walk(usize),
    RotateCW(),
    RotateCCW()
}

type Point = (usize, usize);
type Room = HashMap<Point, Tile>;

fn parse_room(raw: &str) -> Room {
    raw.lines()
        .enumerate()
        .flat_map(|(row, l)| {
            l.chars().enumerate()
                .map(|(col, c)| {
                    let tile = match c {
                        ' ' => Tile::Portal,
                        '#' => Tile::Wall,
                        '.' => Tile::Floor,
                        _ => panic!("unrecogized tile found"),
                    };
                    ((col, row), tile)
                })
                .collect::<Vec<(Point, Tile)>>()
        })
        .collect::<Room>()
}

fn parse_actions(raw: &str) -> Vec<Action> {
    let re = Regex::new(r"(?P<val>:\d+|[LR])").unwrap();
    // re.captures_iter().for_each(|c| dbg!(c));
    re.captures_iter(raw).map(|c| match c["val"].parse::<usize>() {
        Ok(x) => Action::Walk(x),
        Err(_) => match &c["val"] {
            "L" => Action::RotateCCW(),
            "R" => Action::RotateCW(),
            _ => panic!("unknown action")
        }
    }).collect::<Vec<Action>>()
}


fn find_start(cells: &Room) -> Point {
    // Scan along first row
    let mut col = 0;
    loop {
        if let Some(x) = cells.get(&(col, 0)) {
            if *x == Tile::Floor {
                return (col, 0)
            }
        }
        col += 1;
    }
}

fn score(row: usize, col: usize, facing: usize) -> usize {
    1000 * row + 4 * col + facing
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let (cells, actions) = _input.split_once("\n\n").unwrap();
        let cells = parse_room(cells);
        let start = find_start(&cells);
        let actions = parse_actions(actions);
        dbg!(&actions);



        todo!()


    }

    fn part2(&self, _input: &str) -> Option<String> {
        // Some(format!("{}", "undefined"))
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    const INPUT: &str = "        ...#
        .#..
        #...
        ....
...#.......#
........#...
..#....#....
..........#.
        ...#....
        .....#..
        .#......
        ......#.

10R5L5R10L4R5L5
";

    #[test]
    fn test_22a() {
        let solution = Solution {};
        let answer = solution.part1(INPUT).unwrap();
        assert_eq!(answer, "6032");
    }
}
