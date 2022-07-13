use crate::problem::Problem;

use std::collections::HashMap;

pub struct Solution {}

struct SyntaxChecker {
    point_map: HashMap<char, u64>,
    delim_map: HashMap<char, char>,
    inv_delim_map: HashMap<char, char>,
    openers: [char; 4],
}

impl SyntaxChecker {
    fn new(point_map: HashMap<char, u64>) -> Self {
        let delim_map = HashMap::from([(')', '('), (']', '['), ('}', '{'), ('>', '<')]);
        let inv_delim_map = HashMap::from([('(', ')'), ('[', ']'), ('{', '}'), ('<', '>')]);

        let openers = ['(', '[', '{', '<'];

        Self {
            point_map,
            delim_map,
            inv_delim_map,
            openers,
        }
    }

    fn score_error_delim(&self, line: &str) -> u64 {
        let mut prev = vec![];
        for c in line.chars() {
            if self.openers.contains(&c) {
                prev.push(c);
            } else if prev.pop().unwrap() != *self.delim_map.get(&c).unwrap() {
                return *self.point_map.get(&c).unwrap();
            }
        }
        0
    }

    fn score_completion(&self, line: &str) -> u64 {
        let mut prev = vec![];
        for c in line.chars() {
            if self.openers.contains(&c) {
                prev.push(c);
            } else if prev.pop().unwrap() != *self.delim_map.get(&c).unwrap() {
                panic!("corrupt input");
            }
        }
        prev.iter().rev().fold(0, |acc, c| {
            5 * acc
                + self
                    .point_map
                    .get(self.inv_delim_map.get(c).unwrap())
                    .unwrap()
        })
    }
}

fn part1_pointmap() -> HashMap<char, u64> {
    HashMap::from([(')', 3), (']', 57), ('}', 1197), ('>', 25137)])
}

fn part2_pointmap() -> HashMap<char, u64> {
    HashMap::from([(')', 1), (']', 2), ('}', 3), ('>', 4)])
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let checker = SyntaxChecker::new(part1_pointmap());
        let solution: u64 = input
            .lines()
            .map(|line| checker.score_error_delim(line))
            .sum();

        format!("{}", solution)
    }

    fn part2(&self, input: &str) -> String {
        let checker = SyntaxChecker::new(part2_pointmap());
        let mut solution: Vec<u64> = input
            .lines()
            .filter(|line| checker.score_error_delim(line) == 0)
            .map(|line| checker.score_completion(line))
            .collect();

        solution.sort();

        format!("{}", solution[solution.len() / 2])
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_part1_corrupt() {
        let checker = SyntaxChecker::new(part1_pointmap());
        assert_eq!(checker.score_error_delim("{([(<{}[<>[]}>{[]{[(<()>"), 1197);
        assert_eq!(checker.score_error_delim("[[<[([]))<([[{}[[()]]]"), 3);
        assert_eq!(checker.score_error_delim("[{[{({}]{}}([{[{{{}}([]"), 57);
        assert_eq!(checker.score_error_delim("[<(<(<(<{}))><([]([]()"), 3);
        assert_eq!(checker.score_error_delim("<{([([[(<>()){}]>(<<{{"), 25137);
    }
    #[test]
    fn test_part2_completion() {
        let checker = SyntaxChecker::new(part2_pointmap());
        assert_eq!(checker.score_completion("[({(<(())[]>[[{[]{<()<>>"), 288957);
        assert_eq!(checker.score_completion("[(()[<>])]({[<{<<[]>>("), 5566);
        assert_eq!(checker.score_completion("(((({<>}<{<{<>}{[]{[]{}"), 1480781);
        assert_eq!(checker.score_completion("{<[[]]>}<{[{[{[]{()[[[]"), 995444);
        assert_eq!(checker.score_completion("<{([{{}}[<[[[<>{}]]]>[]]"), 294);
    }
}
