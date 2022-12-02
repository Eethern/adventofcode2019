use crate::problem::Problem;
use std::collections::HashMap;

pub struct Solution {}

fn solve(input: &str, pointmap: &HashMap<&str, u32>) -> u32 {
    input
        .lines()
        .fold(0, |acc, l| {
            acc + pointmap.get(&*l.replace(" ", "")).unwrap()
        })
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let pointmap = HashMap::from([
            ("AX", 4),
            ("BX", 1),
            ("CX", 7),
            ("AY", 8),
            ("BY", 5),
            ("CY", 2),
            ("AZ", 3),
            ("BZ", 9),
            ("CZ", 6)
        ]);

        let answer = solve(&_input, &pointmap);

        Some(format!("{}", answer))
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let pointmap = HashMap::from([
            ("AX", 3),
            ("BX", 1),
            ("CX", 2),
            ("AY", 4),
            ("BY", 5),
            ("CY", 6),
            ("AZ", 8),
            ("BZ", 9),
            ("CZ", 7)
        ]);

        let answer = solve(&_input, &pointmap);

        Some(format!("{}", answer))
    }
}
