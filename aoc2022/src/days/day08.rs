use crate::problem::Problem;
use itertools::FoldWhile::{Continue, Done};
use itertools::Itertools;

pub struct Solution {}

struct Grid {
    data: Vec<u32>,
    w: usize,
    h: usize,
}

impl Grid {
    fn new(input: &str) -> Self {
        let rows: Vec<&str> = input.lines().collect();
        let h = rows.len();
        let w = rows[0].len();
        let data = rows
            .iter()
            .flat_map(|s| s.chars().map(|c| c.to_digit(10).unwrap()))
            .collect();

        Self { data, w, h }
    }
    fn get(&self, (x, y): (usize, usize)) -> Option<&u32> {
        if x < self.w && y < self.h {
            self.data.get(y * self.w + x)
        } else {
            None
        }
    }

    fn count_visible(&self) -> usize {
        let mut sum = self.w * 2 + (self.h - 2) * 2;

        for x in 1..self.w - 1 {
            for y in 1..self.h - 1 {
                let curr_height = self.get((x, y)).unwrap();
                if (0..y).all(|i| self.get((x, i)).unwrap() < curr_height) {
                    sum += 1;
                    continue;
                };
                if (0..x).all(|i| self.get((i, y)).unwrap() < curr_height) {
                    sum += 1;
                    continue;
                };
                if ((y + 1)..self.h).all(|i| self.get((x, i)).unwrap() < curr_height) {
                    sum += 1;
                    continue;
                };
                if ((x + 1)..self.w).all(|i| self.get((i, y)).unwrap() < curr_height) {
                    sum += 1;
                    continue;
                };
            }
        }
        sum
    }

    fn best_tree(&self) -> usize {
        let mut max = 0;

        for x in 1..self.w - 1 {
            for y in 1..self.h - 1 {
                let mut sum = 1;
                let curr_height = self.get((x, y)).unwrap();
                sum *= (0..y)
                    .rev()
                    .fold_while(0, |acc, i| {
                        if self.get((x, i)).unwrap() < curr_height {
                            Continue(acc + 1)
                        } else {
                            Done(acc + 1)
                        }
                    })
                    .into_inner();
                sum *= (0..x)
                    .rev()
                    .fold_while(0, |acc, i| {
                        if self.get((i, y)).unwrap() < curr_height {
                            Continue(acc + 1)
                        } else {
                            Done(acc + 1)
                        }
                    })
                    .into_inner();
                sum *= (y + 1..self.h)
                    .fold_while(0, |acc, i| {
                        if self.get((x, i)).unwrap() < curr_height {
                            Continue(acc + 1)
                        } else {
                            Done(acc + 1)
                        }
                    })
                    .into_inner();
                sum *= (x + 1..self.w)
                    .fold_while(0, |acc, i| {
                        if self.get((i, y)).unwrap() < curr_height {
                            Continue(acc + 1)
                        } else {
                            Done(acc + 1)
                        }
                    })
                    .into_inner();

                max = max.max(sum)
            }
        }
        max
    }
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let grid = Grid::new(_input);
        let answer = grid.count_visible();
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let grid = Grid::new(_input);
        let answer = grid.best_tree();
        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "30373
25512
65332
33549
35390
";

    // const INPUT: &str = include_str!("../../inputs/08.in");

    #[test]
    fn test_day08a() {
        let grid = Grid::new(INPUT);
        let answer = grid.count_visible();
        assert_eq!(answer, 21);
    }

    #[test]
    fn test_day08b() {
        let grid = Grid::new(INPUT);
        let answer = grid.best_tree();
        assert_eq!(answer, 8);
    }
}
