use crate::problem::Problem;
use std::collections::HashMap;

pub struct Solution {}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let mut head_pos: (i32, i32) = (0, 0);
        let mut tail_pos: (i32, i32) = (0, 0);
        let mut tail_locations: HashMap<(i32, i32), u32> = HashMap::new();
        _input
            .lines()
            .map(|l| l.split_once(" ").unwrap())
            .for_each(|(dir, mag)| {
                let dp = match dir {
                    "U" => (0, 1),
                    "D" => (0, -1),
                    "L" => (-1, 0),
                    "R" => (1, 0),
                    _ => unreachable!(),
                };

                (0..mag.parse::<u32>().unwrap()).for_each(|_| {
                    let new_head_pos = (head_pos.0 + dp.0, head_pos.1 + dp.1);
                    if chebychev_dist(tail_pos, new_head_pos) > 1 {
                        tail_pos = head_pos;
                    }
                    head_pos = new_head_pos;
                    *tail_locations.entry(tail_pos).or_insert(0) += 1
                });
            });

        let answer = tail_locations.iter().count();
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let knots = 9;
        let mut head_pos: (i32, i32) = (0, 0);
        let mut tail_pos: Vec<(i32, i32)> = vec![(0, 0); knots];
        let mut tail_locations: HashMap<(i32, i32), u32> = HashMap::new();
        tail_locations.insert((0, 0), 1);
        _input
            .lines()
            .map(|l| l.split_once(" ").unwrap())
            .for_each(|(dir, mag)| {
                let dp = match dir {
                    "U" => (0, 1),
                    "D" => (0, -1),
                    "L" => (-1, 0),
                    "R" => (1, 0),
                    _ => unreachable!(),
                };

                for _ in 0..mag.parse().unwrap() {
                    head_pos = (head_pos.0 + dp.0, head_pos.1 + dp.1);
                    let mut parent = head_pos;
                    for i in 0..knots {
                        if chebychev_dist(parent, tail_pos[i]) > 1 {
                            let dx = tail_pos[i].0 - parent.0;
                            let dy = tail_pos[i].1 - parent.1;
                            if dx.abs() > 1 && dy.abs() > 1 {
                                tail_pos[i].0 -= dx.signum();
                                tail_pos[i].1 -= dy.signum();
                            } else if dx.abs() > 1 {
                                tail_pos[i].0 -= dx.signum();
                                tail_pos[i].1 = parent.1;
                            } else if dy.abs() > 1 {
                                tail_pos[i].0 = parent.0;
                                tail_pos[i].1 -= dy.signum();
                            }
                        }
                        parent = tail_pos[i];
                    }
                    *tail_locations.entry(tail_pos[knots - 1]).or_insert(0) += 1;
                }
            });

        let answer = tail_locations.iter().count();
        Some(answer.to_string())
    }
}

fn chebychev_dist(a: (i32, i32), b: (i32, i32)) -> u32 {
    (a.0 - b.0).abs().max((a.1 - b.1).abs()) as u32
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_INPUT: &str = "R 4
U 4
L 3
D 1
R 4
D 1
L 5
R 2
";

    const TEST_INPUT2: &str = "R 5
U 8
L 8
D 3
R 17
D 10
L 25
U 20
";
    #[test]
    fn test_day09a() {
        let solver = Solution {};
        let answer = solver.part1(TEST_INPUT).unwrap();
        assert_eq!(answer, "13");
    }

    #[test]
    fn test_day09b() {
        let solver = Solution {};
        assert_eq!(solver.part2(TEST_INPUT).unwrap(), "1");
        assert_eq!(solver.part2(TEST_INPUT2).unwrap(), "36");
    }
}
