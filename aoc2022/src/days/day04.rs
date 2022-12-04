use crate::problem::Problem;

pub struct Solution {}

type Range = Vec<isize>;

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let pairs = parse_input(_input);
        let answer = pairs.chunks(2).fold(0, |acc, r| {
            acc + if range_len(&r[0]) >= range_len(&r[1]) {
                range_contains(&r[0], &r[1]) as usize
            } else {
                range_contains(&r[1], &r[0]) as usize
            }
        });
        Some(format!("{}", answer))
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let pairs = parse_input(_input);
        let answer = pairs
            .chunks(2)
            .fold(0, |acc, r| acc + range_overlaps(&r[0], &r[1]) as usize);
        Some(format!("{}", answer))
    }
}

fn parse_input(input: &str) -> Vec<Range> {
    input
        .lines()
        .flat_map(|s| {
            s.split(',')
                .map(|c| c.split('-').map(|c| c.parse().unwrap()).collect())
        })
        .collect()
}

fn range_contains(a: &Range, b: &Range) -> bool {
    // Check if a contains b
    b[0] >= a[0] && b[1] <= a[1]
}

fn range_overlaps(a: &Range, b: &Range) -> bool {
    // Check if a overlaps at all with b
    b[0] <= a[1] && b[1] >= a[0]
}

fn range_len(a: &Range) -> usize {
    // Get length of a range
    (a[1] - a[0]) as usize
}

#[cfg(test)]
mod tests {
    use super::*;
    const TEST_INPUT: &'static str = "2-4,6-8
2-3,4-5
5-7,7-9
2-8,3-7
6-6,4-6
2-6,4-8";

    #[test]
    fn test_day04a() {
        let solver = Solution {};
        let answer = solver.part1(TEST_INPUT).unwrap();
        assert_eq!(answer, "2");
    }

    #[test]
    fn test_day04b() {
        let solver = Solution {};
        let answer = solver.part2(TEST_INPUT).unwrap();

        assert_eq!(answer, "4");
    }
}
