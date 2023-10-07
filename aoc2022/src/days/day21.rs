use std::collections::HashMap;

use crate::problem::Problem;

pub struct Solution {}

type Name = String;

#[derive(Debug)]
enum Op {
    Add,
    Sub,
    Mul,
    Div,
}

impl Op {
    fn from_char(c: char) -> Self {
        match c {
            '+' => Op::Add,
            '-' => Op::Sub,
            '*' => Op::Mul,
            '/' => Op::Div,
            _ => unreachable!(),
        }
    }
    fn eval(&self, left: i64, right: i64) -> i64 {
        match self {
            Op::Add => left + right,
            Op::Sub => left - right,
            Op::Mul => left * right,
            Op::Div => left / right,
        }
    }

    fn solve_right(&self, result: i64, left: i64) -> i64 {
        match self {
            Op::Add => result - left,
            Op::Sub => left - result,
            Op::Mul => result / left,
            Op::Div => left / result,
        }
    }

    fn solve_left(&self, result: i64, right: i64) -> i64 {
        match self {
            Op::Add => result - right,
            Op::Sub => result + right,
            Op::Mul => result / right,
            Op::Div => result * right,
        }
    }
}

#[derive(Debug)]
enum Job {
    Constant(i64),
    Expr(Name, Op, Name),
}

fn parse_jobs(jobs: &str) -> HashMap<Name, Job> {
    jobs.lines()
        .map(|l| {
            let (name, e) = l.split_once(": ").unwrap();
            let expr = match e.split(' ').collect::<Vec<&str>>()[..] {
                [c] => Job::Constant(c.parse::<i64>().unwrap()),
                [a, o, b] => Job::Expr(
                    a.to_string(),
                    Op::from_char(o.chars().next().unwrap()),
                    b.to_string(),
                ),
                _ => unreachable!(),
            };
            (name.to_string(), expr)
        })
        .collect()
}

fn trace(source: &String, jobs: &HashMap<Name, Job>, memory: &mut HashMap<Name, i64>) -> i64 {
    // Memoize
    if let Some(&answer) = memory.get(source) {
        return answer;
    }

    match jobs.get(source).unwrap() {
        Job::Constant(c) => *c,
        Job::Expr(a, op, b) => {
            let a_answer = memory.get(a).copied().unwrap_or_else(|| {
                let a_answer = trace(a, jobs, memory);
                memory.insert(a.to_string(), a_answer);
                a_answer
            });

            let b_answer = memory.get(b).copied().unwrap_or_else(|| {
                let b_answer = trace(b, jobs, memory);
                memory.insert(b.to_string(), b_answer);
                b_answer
            });

            op.eval(a_answer, b_answer)
        }
    }
}

fn populate_memory(
    source: &String,
    jobs: &HashMap<Name, Job>,
    memory: &mut HashMap<Name, i64>,
) -> Option<i64> {
    if source == "humn" {
        return None;
    }

    let value = match jobs.get(source).unwrap() {
        Job::Constant(c) => *c,
        Job::Expr(a, op, b) => {
            let left = populate_memory(a, jobs, memory);
            let right = populate_memory(b, jobs, memory);
            op.eval(left?, right?)
        }
    };

    memory.insert(source.to_string(), value);
    Some(value)
}

fn populate_above_humn(jobs: &HashMap<Name, Job>, memory: &mut HashMap<Name, i64>) -> i64 {
    let mut current_node = "root";
    let mut result = 0;
    let mut correction = -1;
    while current_node != "humn" {
        let (left, op, right) = match jobs.get(current_node).unwrap() {
            Job::Expr(l, op, r) => (l, op, r),
            Job::Constant(_) => unreachable!(),
        };

        (current_node, result) = match (memory.get(left), memory.get(right)) {
            (None, Some(&r)) => (left, op.solve_left(result, r)),
            (Some(&l), None) => (right, op.solve_right(result, l)),
            _ => unreachable!(),
        };

        result *= correction;
        correction = 1;
    }

    result
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let jobs = parse_jobs(_input);
        let mut memory = HashMap::new();
        let answer = trace(&"root".to_string(), &jobs, &mut memory);

        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let jobs = parse_jobs(_input);
        let mut memory = HashMap::new();
        populate_memory(&"root".to_string(), &jobs, &mut memory);
        let answer = populate_above_humn(&jobs, &mut memory);

        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "root: pppw + sjmn
dbpl: 5
cczh: sllz + lgvd
zczc: 2
ptdq: humn - dvpt
dvpt: 3
lfqf: 4
humn: 5
ljgn: 2
sjmn: drzm * dbpl
sllz: 4
pppw: cczh / lfqf
lgvd: ljgn * ptdq
drzm: hmdt - zczc
hmdt: 32
";

    #[test]
    fn test_day21a() {
        let jobs = parse_jobs(INPUT);
        let mut memory = HashMap::new();
        let answer = trace(&"root".to_string(), &jobs, &mut memory);
        assert_eq!(answer, 152);
    }

    #[test]
    fn test_day21b() {
        let solution = Solution {};
        let answer = solution.part2(INPUT).unwrap();

        assert_eq!(answer, "301");
    }
}
