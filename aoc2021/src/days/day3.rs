use crate::problem::Problem;

pub struct DayThree {}

impl Problem for DayThree {
    fn part1(&self, input: &str) -> String {
        let numbers: Vec<&str> = input.split("\n")
            .collect();

        let n: usize = numbers.len();
        let k: usize = numbers[0].len();
            
        let mut counts =  vec![0; k];
        for r in 0..n {
            for c in 0..k {
                counts[c] += numbers[r].as_bytes()[c] as usize - 48;
            }
        }

        let mut gamma_rate = 0;
        let mut epsilon_rate = 0;
        let threshold = n / 2;

        for (i, num_ones) in counts.iter().enumerate() {
            if num_ones > &threshold {
                gamma_rate += 1 << (k-i-1);
            }
            else {
                epsilon_rate += 1 << (k-i-1);
            }
        }

        format!("{}", gamma_rate * epsilon_rate)
    }

    fn part2(&self, input: &str) -> String {

        let numbers: Vec<i32> = input.lines()
            .map(|bstr| i32::from_str_radix(bstr, 2).expect("Not a binary number"))
            .collect();

        format!("{}", "undefined")

    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
