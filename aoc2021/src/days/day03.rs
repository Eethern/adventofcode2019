use crate::problem::Problem;

pub struct Solution {}

fn search(numbers: &Vec<u32>, width: u32, sign: bool) -> u32 {
    (0..width)
        .rev()
        .scan(numbers.clone(), |acc, i| {
            let majority = acc.iter().filter(|&n| n & 1 << i > 0).count() >= (acc.len() + 1) / 2;

            *acc = acc
                .iter()
                .filter(|n| (*n & 1 << i > 0) == (majority ^ sign))
                .map(|&n| n)
                .collect();

            acc.first().copied()
        })
        .last()
        .unwrap()
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let numbers: Vec<&str> = input.split('\n').collect();

        let n: usize = numbers.len();
        let k: usize = numbers[0].len();

        let mut counts = vec![0; k];
        for num in numbers {
            let bytes = num.as_bytes();
            for (c, count) in counts.iter_mut().enumerate() {
                *count += bytes[c] as usize - 48;
            }
            // for c in 0..k {
            //     counts[c] += num.as_bytes()[c] as usize - 48;
            // }
        }

        let mut gamma_rate = 0;
        let mut epsilon_rate = 0;
        let threshold = n / 2;

        for (i, num_ones) in counts.iter().enumerate() {
            if num_ones > &threshold {
                gamma_rate += 1 << (k - i - 1);
            } else {
                epsilon_rate += 1 << (k - i - 1);
            }
        }

        format!("{}", gamma_rate * epsilon_rate)
    }

    fn part2(&self, input: &str) -> String {
        let numbers = input
            .lines()
            .map(|line| u32::from_str_radix(line, 2).unwrap())
            .collect::<Vec<u32>>();

        let oxygen = search(&numbers, 12, true);
        let co2 = search(&numbers, 12, false);

        format!("{}", oxygen * co2)
    }
}
