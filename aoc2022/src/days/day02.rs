use crate::problem::Problem;
use std::collections::HashMap;

pub struct Solution {}

fn solve(input: &str, pointmap: &HashMap<&str, u32>) -> u32 {
    input
        .lines()
        .fold(0, |acc, l| {
            acc + pointmap.get(l).unwrap()
        })
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let pointmap = HashMap::from([
            ("A X", 4),
            ("B X", 1),
            ("C X", 7),
            ("A Y", 8),
            ("B Y", 5),
            ("C Y", 2),
            ("A Z", 3),
            ("B Z", 9),
            ("C Z", 6)
        ]);

        let answer = solve(&_input, &pointmap);

        Some(format!("{}", answer))
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let pointmap = HashMap::from([
            ("A X", 3),
            ("B X", 1),
            ("C X", 2),
            ("A Y", 4),
            ("B Y", 5),
            ("C Y", 6),
            ("A Z", 8),
            ("B Z", 9),
            ("C Z", 7)
        ]);

        let answer = solve(&_input, &pointmap);

        Some(format!("{}", answer))
    }
}
