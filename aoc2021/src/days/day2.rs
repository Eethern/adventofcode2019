use crate::problem::Problem;

pub struct Solution {}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let (hor, depth) = input.lines().map(|cmd| cmd.split_once(' ').unwrap()).fold(
            (0, 0),
            |(h, d), (cmd, val)| match (cmd, val.parse::<u32>().unwrap()) {
                ("forward", v) => (h + v, d),
                ("down", v) => (h, d + v),
                ("up", v) => (h, d - v),
                _ => (h, d),
            },
        );

        format!("{:?}", hor * depth)
    }

    fn part2(&self, input: &str) -> String {
        let (hor, depth, _) = input.lines().map(|cmd| cmd.split_once(' ').unwrap()).fold(
            (0, 0, 0),
            |(h, d, a), (cmd, val)| match (cmd, val.parse::<u32>().unwrap()) {
                ("forward", v) => (h + v, d + a * v, a),
                ("down", v) => (h, d, a + v),
                ("up", v) => (h, d, a - v),
                _ => (h, d, a),
            },
        );

        format!("{}", hor * depth)
    }
}
