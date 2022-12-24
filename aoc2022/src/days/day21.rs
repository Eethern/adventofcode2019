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
                [a, o, b] => {
                    let op = match o.chars().next().unwrap() {
                        '+' => Op::Add,
                        '-' => Op::Sub,
                        '*' => Op::Mul,
                        '/' => Op::Div,
                        _ => unreachable!(),
                    };
                    Job::Expr(a.to_string(), op, b.to_string())
                }
                _ => unreachable!(),
            };
            (name.to_string(), expr)
        })
        .collect()
}

fn trace(
    source: &String,
    jobs: &HashMap<Name, Job>,
    memory: &mut HashMap<Name, i64>,
    humn: bool,
) -> i64 {
    if let Some(&answer) = memory.get(source) {
        return answer;
    }

    return match jobs.get(source).unwrap() {
        Job::Constant(c) => *c,
        Job::Expr(a, op, b) => {
            let a_answer = memory.get(a).copied().unwrap_or_else(|| {
                let a_answer = trace(a, jobs, memory, humn);
                memory.insert(a.to_string(), a_answer);
                a_answer
            });

            let b_answer = memory.get(b).copied().unwrap_or_else(|| {
                let b_answer = trace(b, jobs, memory, humn);
                memory.insert(b.to_string(), b_answer);
                b_answer
            });

            match op {
                Op::Add => a_answer + b_answer,
                Op::Sub => a_answer - b_answer,
                Op::Mul => a_answer * b_answer,
                Op::Div => a_answer / b_answer,
            }
        }
    };
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let jobs = parse_jobs(_input);
        let mut memory = HashMap::new();
        let answer = trace(&"root".to_string(), &jobs, &mut memory, false);

        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        // Some(format!("{}", "undefined"))
        None
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
        let jobs = parse_jobs(INPUT);
        let mut memory = HashMap::new();
        let answer = trace(&"root".to_string(), &jobs, &mut memory);
        assert_eq!(answer, 152);
    }
}
