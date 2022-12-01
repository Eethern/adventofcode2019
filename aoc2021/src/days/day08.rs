use crate::problem::Problem;

pub struct Solution {}



impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let candidates = vec![2, 3, 4, 7];
        let answer = input
            .lines()
            .flat_map(|l| {
                l.split(" | ").last().unwrap().split(' ').filter(|seq| {
                    let len = seq.len();
                    candidates.contains(&len)
                })
            })
            .count();
        format!("{}", answer)
    }

    fn part2(&self, input: &str) -> String {
        let answer = input.lines().map(|line| {
            let mut parts = line.split(" | ");
            let codes = parts.next().unwrap().split(' ');
            let one = codes.clone().find(|d| d.len() == 2).unwrap();
            let four = codes.clone().find(|d| d.len() == 4).unwrap();

            parts.next()
                .unwrap()
                .split(' ')
                .map(|d| match d.len() {
                    2 => 1,
                    3 => 7,
                    4 => 4,
                    7 => 8,
                    len => match (
                        len,
                        d.chars().filter(|&b| one.contains(b)).count(),
                        d.chars().filter(|&b| four.contains(b)).count()
                    ) {
                        (5, 1, 3) => 5,
                        (5, 2, 3) => 3,
                        (5, 1, 2) => 2,
                        (6, 1, _) => 6,
                        (6, _, 3) => 0,
                        (6, _, 4) => 9,
                        _ => unreachable!()
                    }

                })
                .enumerate()
                .fold(0, |acc, (i, n)| acc + n * 10_u32.pow(3 - i as u32))
        }).sum::<u32>();

        format!("{}", answer)
    }
}
