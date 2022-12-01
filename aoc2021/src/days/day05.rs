use crate::problem::Problem;
use std::collections::HashMap;

pub struct Solution {}

#[derive(Debug)]
struct Point {
    x: i32,
    y: i32,
}

#[derive(Debug)]
struct Line {
    start: Point,
    end: Point,
}

struct Grid {
    cells: HashMap<(i32, i32), u32>,
    skip_diagonals: bool,
}

impl Grid {
    fn setup_grid(input: &str, skip_diagonals: bool) -> Self {
        let cells = HashMap::new();
        let mut grid = Self {
            cells,
            skip_diagonals,
        };

        // Add the lines
        let lines: Vec<Line> = input.lines().map(parse_line).collect();
        for line in lines.iter() {
            grid.add_line(line);
        }
        grid
    }

    fn add_line(&mut self, line: &Line) {
        let line = &*line;
        let dx = (line.end.x - line.start.x).signum();
        let dy = (line.end.y - line.start.y).signum();

        if self.skip_diagonals && dx != 0 && dy != 0 {
            return;
        }

        let mut x = line.start.x;
        let mut y = line.start.y;

        while (x, y) != (line.end.x + dx, line.end.y + dy) {
            *self.cells.entry((x, y)).or_insert(0) += 1;
            x += dx;
            y += dy;
        }
    }

    fn get_overlaps(self) -> u32 {
        let mut num_overlaps = 0;
        for (_, value) in self.cells.into_iter() {
            if value > 1 {
                num_overlaps += 1;
            }
        }

        num_overlaps
    }
}

fn parse_line(l: &str) -> Line {
    let points: Vec<Vec<i32>> = l
        .split(" -> ")
        .map(|p| p.split(',').map(|x| x.parse().unwrap()).collect())
        .collect();

    let start = Point {
        x: points[0][0],
        y: points[0][1],
    };
    let end = Point {
        x: points[1][0],
        y: points[1][1],
    };

    Line { start, end }
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let grid = Grid::setup_grid(input, true);
        let overlaps = grid.get_overlaps();

        format!("{}", overlaps)
    }

    fn part2(&self, input: &str) -> String {
        let grid = Grid::setup_grid(input, false);
        let overlaps = grid.get_overlaps();

        format!("{}", overlaps)
    }
}
