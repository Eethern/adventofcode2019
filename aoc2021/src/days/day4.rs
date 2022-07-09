use crate::problem::Problem;

pub struct DayFour {}

fn parse_input(input: &str) -> (Vec<i32>, Vec<Vec<i32>>) {
    let (nums, boards) = input.split_once("\n\n").unwrap();
    let numbers = parse_numbers(nums);

    let mut boards: Vec<Vec<i32>> = boards
        .split("\n\n")
        .map(|b| {
            b.split("\n").map(|r| {
                {
                    r.split_ascii_whitespace()
                        .map(|n| n.parse().unwrap())
                        .collect()
                }
                .collect()
            })
        })
        .collect();

    (numbers, boards)
}

fn parse_numbers(numbers: &str) -> Vec<i32> {
    numbers
        .split_ascii_whitespace()
        .map(|s| s.parse().unwrap())
        .collect()
}

impl Problem for DayFour {
    fn part1(&self, input: &str) -> String {
        let (numbers, boards) = parse_input(input);
        format!("{:?}", numbers)
    }

    fn part2(&self, input: &str) -> String {
        format!("{}", "undefined")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
