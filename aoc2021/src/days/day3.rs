use crate::problem::Problem;

pub struct DayThree {}

impl Problem for DayThree {
    fn part1(&self, input: &str) -> String {
        let numbers: Vec<&str> = input.split('\n')
            .collect();

        let n: usize = numbers.len();
        let k: usize = numbers[0].len();
            
        let mut counts =  vec![0; k];
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
                gamma_rate += 1 << (k-i-1);
            }
            else {
                epsilon_rate += 1 << (k-i-1);
            }
        }

        format!("{}", gamma_rate * epsilon_rate)
    }

    fn part2(&self, _input: &str) -> String {

        "undefined".to_string()
        // format!("{}", "undefined")

    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
