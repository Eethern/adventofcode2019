use std::collections::VecDeque;

use crate::problem::Problem;

pub struct Solution {}

type Entry = (usize, i64);

fn mix(entries: &mut Vec<Entry>, rounds: usize) {
    let n_items = entries.len();

    for _ in 0..rounds {
        for original_idx in 0..entries.len() {
            // find new idx matching original index
            let idx = entries.iter().position(|(x, _)| *x == original_idx).unwrap();

            // get value
            let value = entries[idx].1;

            // find target index
            let new_idx = (idx as i64 + value).rem_euclid(n_items as i64 - 1);

            // update entries
            let elem = entries.remove(idx);
            entries.insert(new_idx as usize, elem);
        }
    }
}

fn decrypt(input: &str, rounds: usize, key: Option<i64>)  -> i64 {
    let mut entries = input
        .lines()
        .map(|n| n.parse::<i64>().unwrap())
        .enumerate()
        .collect::<Vec<Entry>>();

    if let Some(k) = key {
        entries.iter_mut().for_each(|(_, v)| *v*=k);
    }

    mix(&mut entries, rounds);

    let n_items = entries.len();
    let zero = entries.iter().position(|&(_, n)| n == 0).unwrap();
    entries[(zero + 1000).rem_euclid(n_items)].1
        + entries[(zero + 2000).rem_euclid(n_items)].1
        + entries[(zero + 3000).rem_euclid(n_items)].1
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let answer = decrypt(_input, 1, None);
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let decryption_key: i64 = 811589153;
        let rounds = 10;
        let answer = decrypt(_input, rounds, Some(decryption_key));
        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "1
2
-3
3
-2
0
4";

    #[test]
    fn test_day20a() {
        let solution = Solution {};
        let answer = solution.part1(INPUT).unwrap();

        assert_eq!(answer, "3");
    }

    #[test]
    fn test_day20b() {
        let solution = Solution {};
        let answer = solution.part2(INPUT).unwrap();

        assert_eq!(answer, "1623178306");
    }
}
