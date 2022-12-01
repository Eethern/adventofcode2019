use crate::problem::Problem;

pub struct Solution {}

fn parse(input: &str) -> Vec<i32> {
    input
        .split("\n\n")
        .map(|x| x.lines().fold(0, |acc, n| acc + n.parse::<i32>().unwrap())).collect()
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let weights = parse(&_input);
        let max = weights.iter().max().unwrap();

        Some(format!("{}", max))
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let mut weights = parse(&_input);
        weights.sort();
        let answer: i32 = weights[weights.len()-3..].iter().sum();
        Some(format!("{}", answer))
    }
}
