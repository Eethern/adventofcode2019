use crate::problem::Problem;
use std::collections::BinaryHeap;

pub struct Solution {}

fn parse(input: &str) -> BinaryHeap<i32> {
    input
        .split("\n\n")
        .map(|x| x.lines().fold(0, |acc, n| acc + n.parse::<i32>().unwrap()))
        .collect::<BinaryHeap<i32>>()
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let weights = parse(&_input);
        let max = weights.peek().unwrap();

        Some(format!("{}", max))
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let mut weights = parse(&_input);
        let answer: i32 = weights.pop().unwrap() + weights.pop().unwrap() + weights.peek().unwrap();
        Some(format!("{}", answer))
    }
}
