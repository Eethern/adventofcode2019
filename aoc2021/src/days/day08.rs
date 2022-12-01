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

    fn part2(&self, _input: &str) -> String {
        format!("{}", "undefined")
    }
}

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn test_part2_example() {
//         let input = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf\n";

//         let answer = input.lines().map(|line| {
//             let mut parts = line.split(" | ");
//             let codes = parts.next().unwrap().split(' ');
//             let one = codes.clone().find(|d| d.len() == 2).unwrap();
//             let four = codes.clone().find(|d| d.len() == 2).unwrap();

//             parts.next()
//                 .unwrap()
//                 .split(' ')
//                 .skip(1)
//                 .map(|d| match d.len() {
//                     2 => 1,
//                     3 => 7,
//                     4 => 4,
//                     7 => 8,
//                     len => match (
//                         len,
//                         d.chars().filter(|&b| one.contains(b)).count(),
//                         d.chars().filter(|&b| four.contains(b)).count()
//                     ) {
//                         (5, 1, 3) => 5,
//                         (5, 2, 3) => 3,
//                         (5, _, 2) => 2,
//                         (6, 1, _) => 6,
//                         (6, _, 3) => 0,
//                         (6, _, 4) => 9,
//                         _ => unreachable!()
//                     }

//                 })
//                 .enumerate()
//                 .fold(0, |acc, (i, n)| acc + n * 10_u32.pow(3 - i as u32))
//         }).sum::<u32>();

//         assert_eq!(answer, 5353);

//     }
// }
