use crate::problem::Problem;
use std::collections::HashMap;

pub struct Solution {}

const SIZE: isize = 10;

const OFFSETS: [(isize, isize); 8] = [
    (1, 0),
    (1, -1),
    (0, -1),
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
];


fn in_bounds(p: (isize, isize)) -> bool {
    p.0 >= 0 && p.1 >= 0 && p.0 < SIZE as isize && p.1 < SIZE as isize
}

fn get_neighbors(center: (isize, isize)) -> Vec<(isize, isize)> {
    OFFSETS
        .iter()
        .map(|(x, y)| (center.0 + x, center.1 + y))
        .filter(|p| in_bounds(*p))
        .collect()
}

fn flash(grid: &mut HashMap<(isize, isize), u32>, p: (isize, isize)) -> u32 {
    (*grid.get(&p).unwrap() > 9)
        .then(|| {
            *grid.get_mut(&p).unwrap() = 0;
            get_neighbors(p).iter().fold(1, |acc, n| {
                acc + (*grid.get(n).unwrap() > 0)
                    .then(|| {
                        *grid.get_mut(&n).unwrap() += 1;
                        flash(grid, *n)
                    })
                    .unwrap_or(0)
            })
        })
        .unwrap_or(0)
}

fn tick(grid: &mut HashMap<(isize, isize), u32>) -> u32 {
    grid.iter_mut().for_each(|(_, e)| *e += 1);
    (0..SIZE).fold(0, |acc, y| {
        acc + (0..SIZE).fold(0, |acc, x| acc + flash(grid, (x, y)))
    })
}

fn parse_input(input: &str) -> HashMap<(isize, isize), u32> {
    input
        .lines()
        .enumerate()
        .flat_map(|(y, row)| {
            row.chars()
                .enumerate()
                .map(move |(x, c)| ((x as isize, y as isize), c as u32 - 0x30))
        })
        .collect::<HashMap<(isize, isize), u32>>()
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let mut grid = parse_input(input);
        let n_flashes = (0..100).fold(0, |acc, _| acc + tick(&mut grid));

        format!("{}", n_flashes)
    }

    fn part2(&self, input: &str) -> String {
        let mut grid = parse_input(input);

        let mut iterations = 1;
        loop {
            if tick(&mut grid) == (SIZE as u32).pow(2) {break}
            iterations += 1;
        }

        format!("{}", iterations)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "5483143223
2745854711
5264556173
6141336146
6357385478
4167524645
2176841721
6882881134
4846848554
5283751526";

        let mut grid = parse_input(input);
        let mut n_flashes = (0..10).fold(0, |acc, _| acc + tick(&mut grid));
        assert_eq!(n_flashes, 204);
        n_flashes += (0..90).fold(0, |acc, _| acc + tick(&mut grid));
        assert_eq!(n_flashes, 1656);
    }
}
