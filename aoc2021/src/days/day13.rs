use crate::problem::Problem;

type Point = (i32, i32);

pub struct Solution {}
fn parse_input(input: &str) -> (Vec<Point>, Vec<(&str, i32)>) {
    let (dots, instr) = input.split_once("\n\n").unwrap();
    let points: Vec<Point> = dots
        .lines()
        .map(|s| {
            let (a, b) = s.split_once(',').unwrap();
            (a.parse().unwrap(), b.parse().unwrap())
        })
        .collect();

    let folds: Vec<(&str, i32)> = instr
        .lines()
        .map(|l| {
            l.split_ascii_whitespace()
                .last()
                .unwrap()
                .split_once('=')
                .unwrap()
        })
        .map(|(axis, val)| (axis, val.parse::<i32>().unwrap()))
        .collect();

    (points, folds)
}

fn fold(points: Vec<Point>, fold: (&str, i32)) -> Vec<Point> {
    let mut new_points = points
        .iter()
        .map(|c|
             match fold {
                 ("x", v) => if c.0 > v {(2 * v - c.0, c.1)} else {*c},
                 ("y", v) => if c.1 > v {(c.0, 2 * v - c.1)} else {*c},
                 _ => unreachable!(),
             })
        .collect::<Vec<Point>>();

    new_points.sort();
    new_points.dedup();

    new_points
}

fn display_points(points: Vec<Point>) -> String {
    let mut chars: Vec<char> = Vec::new();
    let width = 50;
    let height = 6;
    for _ in 0..height {
        chars.push('\n');
        for _ in 0..width {
            chars.push(' ');
        }
    }

    for (x, y) in points {
        chars[(y * (width+1) + x + y) as usize] = '█';
    }

    chars.iter().collect()
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let (points, folds) = parse_input(input);
        let answer = fold(points, folds[0]).len();

        format!("{}", answer)
    }

    fn part2(&self, input: &str) -> String {
        let (points, folds) = parse_input(input);
        let answer: Vec<Point> = folds.iter().fold(points, |acc, &f| fold(acc, f));

        format!("\n{}", display_points(answer))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "6,10
0,14
9,10
0,3
10,4
4,11
6,0
6,12
4,1
0,13
10,12
3,4
3,0
8,4
1,10
2,14
8,10
9,0

fold along y=7
fold along x=5";
        let (points, folds) = parse_input(input);
        let answer = fold(points, folds[0]);
        dbg!(&answer);
        assert_eq!(answer.len(), 17);
    }
}

