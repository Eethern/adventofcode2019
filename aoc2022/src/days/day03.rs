use crate::problem::Problem;

use itertools::Itertools;
use std::collections::HashMap;
use std::collections::HashSet;

pub struct Solution {}

fn get_priority(c: char) -> u32 {
    match c {
        'a'..='z' => c as u32 - 'a' as u32 + 1,
        'A'..='Z' => c as u32 - 'A' as u32 + 27,
        _ => unreachable!(),
    }
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let mut set: HashSet<char> = HashSet::new();
        let sum = _input
            .lines()
            .map(|l| {
                let (left, right) = l.split_at(l.len() / 2);
                set.extend(left.chars());
                let out = match right
                    .chars()
                    .find(|c| set.contains(c)) {
                        Some(c) => get_priority(c),
                        None => 0,
                    };
                set.clear();
                out
            })
            .sum::<u32>();

        Some(format!("{}", sum))
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let mut freq: HashMap<char, u32> = HashMap::new();
        let sum = &_input
            .lines()
            .chunks(3)
            .into_iter()
            .map(|chunk| {
                chunk.for_each(|l| {
                    l.chars().unique().for_each(|c| {
                        *freq.entry(c).or_insert(0) += 1;
                    })
                });
                let out = freq
                    .iter()
                    .filter(|(_, &v)| v >= 3)
                    .fold(0, |acc, (&k, _)| acc + get_priority(k));

                // Clear for next group rather than reinit
                freq.clear();
                out
            })
            .sum::<u32>();

        Some(format!("{}", sum))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_INPUT: &'static str = "vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw";

    #[test]
    fn test_day03a() {
        let solver = Solution {};
        let answer = solver.part1(TEST_INPUT);
        assert_eq!(answer, Some("157".to_string()));
    }

    #[test]
    fn test_day03b() {
        let solver = Solution {};
        let answer = solver.part2(TEST_INPUT);
        assert_eq!(answer, Some("70".to_string()));
    }
}
