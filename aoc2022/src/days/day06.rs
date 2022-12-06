use crate::problem::Problem;

pub struct Solution {}

fn unique_chars(s: &[char]) -> bool {
    let v: Vec<char> = s.to_vec();
    let mut y = v.clone();
    y.sort();
    y.dedup();
    v.len() == y.len()
}

fn find_first_unique_group(_input: &str, group_size: usize) -> usize {
        _input.chars().collect::<Vec<char>>()
            .windows(group_size)
            .into_iter()
            .position(|w| unique_chars(w))
            .unwrap()
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let answer = find_first_unique_group(_input, 4) + 4;
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let answer = find_first_unique_group(_input, 14) + 14;
        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "mjqjpqmgbljsphdztnvjfqwrcgsmlb";

    #[test]
    fn test_day06a() {
        let v = INPUT.chars().collect::<Vec<char>>();
        let windows = v.windows(4);
        let answer = windows.into_iter().position(|w| unique_chars(w)).unwrap() + 4;

        assert_eq!(7, answer);
    }
}
