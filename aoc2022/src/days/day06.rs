extern crate test;

use crate::problem::Problem;
use std::collections::HashMap;

pub struct Solution {}

fn unique_chars(s: &[char]) -> bool {
    let v: Vec<char> = s.to_vec();
    let mut y = v.clone();
    y.sort();
    y.dedup();
    v.len() == y.len()
}

fn find_first_unique_group_vec_clone(_input: &str, group_size: usize) -> Option<usize> {
    let result = _input
        .chars()
        .collect::<Vec<char>>()
        .windows(group_size)
        .into_iter()
        .position(|w| unique_chars(w))
        .unwrap()
        + group_size;

    Some(result)
}

fn find_first_unique_group_hashmap(_input: &str, group_size: usize) -> Option<usize> {
    let stream = _input.as_bytes();
    let mut freqs: HashMap<u8, usize> = HashMap::new();

    // Initial fill
    for i in 0..group_size {
        *freqs.entry(stream[i]).or_insert(0) += 1;
    }

    for i in group_size.._input.len(){
        let left = stream[i - group_size];
        let right = stream[i];
        freqs.entry(left).and_modify(|e| *e -= 1);
        if *freqs.get(&left).unwrap() == 0 {
            freqs.remove(&left);
        }
        *freqs.entry(right).or_insert(0) += 1;
        if freqs.len() == group_size && freqs.values().all(|&v| v == 1){
            return Some(i + 1);
        }
    }
    None
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let answer = find_first_unique_group_vec_clone(_input, 4).unwrap();
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let answer = find_first_unique_group_hashmap(_input, 14).unwrap();
        Some(answer.to_string())
    }
}

#[cfg(test)]
mod benches {
    use super::*;
    use test::Bencher;

    static BENCH_SIZE: usize = 20;
    static BENCH_INPUT: &str = include_str!("../../inputs/06.in");

    #[bench]
    fn copy_vector_approach_small(b: &mut Bencher) {
        b.iter(|| {
            (0..BENCH_SIZE)
                .map(|_| find_first_unique_group_vec_clone(BENCH_INPUT, 4).unwrap())
                .collect::<Vec<_>>()
        })
    }

    #[bench]
    fn hashmap_approach_small(b: &mut Bencher) {
        b.iter(|| {
            (0..BENCH_SIZE)
                .map(|_| find_first_unique_group_hashmap(BENCH_INPUT, 4).unwrap())
                .collect::<Vec<_>>()
        })
    }

    #[bench]
    fn copy_vector_approach_large(b: &mut Bencher) {
        b.iter(|| {
            (0..BENCH_SIZE)
                .map(|_| find_first_unique_group_vec_clone(BENCH_INPUT, 14).unwrap())
                .collect::<Vec<_>>()
        })
    }

    #[bench]
    fn hashmap_approach_large(b: &mut Bencher) {
        b.iter(|| {
            (0..BENCH_SIZE)
                .map(|_| find_first_unique_group_hashmap(BENCH_INPUT, 14).unwrap())
                .collect::<Vec<_>>()
        })
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT1: &str = "mjqjpqmgbljsphdztnvjfqwrcgsmlb";
    const INPUT2: &str = "bvwbjplbgvbhsrlpgdmjqwftvncz";
    const INPUT3: &str = "nppdvjthqldpwncqszvftbrmjlhg";
    const INPUT4: &str = "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg";
    const INPUT5: &str = "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw";

    #[test]
    fn test_day06a() {
        assert_eq!(7, find_first_unique_group_vec_clone(INPUT1, 4).unwrap());
        assert_eq!(5, find_first_unique_group_vec_clone(INPUT2, 4).unwrap());
        assert_eq!(6, find_first_unique_group_vec_clone(INPUT3, 4).unwrap());
        assert_eq!(10, find_first_unique_group_vec_clone(INPUT4, 4).unwrap());
        assert_eq!(11, find_first_unique_group_vec_clone(INPUT5, 4).unwrap());

        assert_eq!(7, find_first_unique_group_hashmap(INPUT1, 4).unwrap());
        assert_eq!(5, find_first_unique_group_hashmap(INPUT2, 4).unwrap());
        assert_eq!(6, find_first_unique_group_hashmap(INPUT3, 4).unwrap());
        assert_eq!(10, find_first_unique_group_hashmap(INPUT4, 4).unwrap());
        assert_eq!(11, find_first_unique_group_hashmap(INPUT5, 4).unwrap());
    }

    #[test]
    fn test_day06b() {
        assert_eq!(19, find_first_unique_group_vec_clone(INPUT1, 14).unwrap());
        assert_eq!(23, find_first_unique_group_vec_clone(INPUT2, 14).unwrap());
        assert_eq!(23, find_first_unique_group_vec_clone(INPUT3, 14).unwrap());
        assert_eq!(29, find_first_unique_group_vec_clone(INPUT4, 14).unwrap());
        assert_eq!(26, find_first_unique_group_vec_clone(INPUT5, 14).unwrap());

        assert_eq!(19, find_first_unique_group_hashmap(INPUT1, 14).unwrap());
        assert_eq!(23, find_first_unique_group_hashmap(INPUT2, 14).unwrap());
        assert_eq!(23, find_first_unique_group_hashmap(INPUT3, 14).unwrap());
        assert_eq!(29, find_first_unique_group_hashmap(INPUT4, 14).unwrap());
        assert_eq!(26, find_first_unique_group_hashmap(INPUT5, 14).unwrap());
    }
}
