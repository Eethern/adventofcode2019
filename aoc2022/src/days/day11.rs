use crate::problem::Problem;
use std::collections::VecDeque;

pub struct Solution {}

enum Value {
    Old,
    Const(i64),
}

enum Op {
    Multiply(Value, Value),
    Add(Value, Value),
}

enum Cond {
    IfDivisibleBy(i64, usize, usize),
}

struct Monkey {
    id: usize,
    items: VecDeque<i64>,
    op: Op,
    cond: Cond,
}

impl Monkey {
    fn inspect(&mut self, denom: i64, use_mod: bool) -> Option<i64> {
        match self.next() {
            Some(item) => Some(if use_mod {
                self.op(item) % denom
            } else {
                self.op(item) / denom
            }),
            None => None,
        }
    }

    fn test(&self, item: i64) -> usize {
        match self.cond {
            Cond::IfDivisibleBy(denom, t, f) => {
                if item % denom == 0 {
                    t
                } else {
                    f
                }
            }
        }
    }
    fn op(&self, item: i64) -> i64 {
        match &self.op {
            Op::Multiply(a, b) => {
                let a = match a {
                    Value::Old => item,
                    Value::Const(c) => *c,
                };
                let b = match b {
                    Value::Old => item,
                    Value::Const(c) => *c,
                };
                a * b
            }
            Op::Add(a, b) => {
                let a = match a {
                    Value::Old => item,
                    Value::Const(c) => *c,
                };
                let b = match b {
                    Value::Old => item,
                    Value::Const(c) => *c,
                };
                a + b
            }
        }
    }
    fn next(&mut self) -> Option<i64> {
        self.items.pop_front()
    }
    fn receive(&mut self, item: i64) {
        self.items.push_back(item);
    }
}

fn parse_input(raw: &str) -> Vec<Monkey> {
    raw.split("\n\n")
        .map(|m| parse_monkey(m))
        .collect::<Vec<Monkey>>()
}

fn parse_monkey(raw: &str) -> Monkey {
    let lines: Vec<&str> = raw.lines().collect();

    Monkey {
        id: parse_id(lines[0]),
        items: parse_items(lines[1]),
        op: parse_op(lines[2]),
        cond: parse_cond(lines[3], lines[4], lines[5]),
    }
}

fn parse_items(raw: &str) -> VecDeque<i64> {
    raw.split(": ")
        .last()
        .unwrap()
        .split(", ")
        .map(|n| n.parse::<i64>().unwrap())
        .collect::<VecDeque<i64>>()
}

fn parse_id(raw: &str) -> usize {
    raw.split(" ")
        .last()
        .unwrap()
        .replace(":", "")
        .parse::<usize>()
        .unwrap()
}

fn parse_value(raw: &str) -> Value {
    match raw {
        "old" => Value::Old,
        n => Value::Const(n.parse().unwrap()),
        _ => unreachable!(),
    }
}

fn parse_op(raw: &str) -> Op {
    let (r1, op, r2) = match raw.split(" ").collect::<Vec<&str>>()[5..] {
        [r1, op, r2] => (r1, op, r2),
        _ => unreachable!(),
    };
    let r1 = parse_value(r1);
    let r2 = parse_value(r2);

    match op {
        "*" => Op::Multiply(r1, r2),
        "+" => Op::Add(r1, r2),
        _ => unreachable!(),
    }
}

fn play_rounds(
    monkeys: &mut Vec<Monkey>,
    n_rounds: usize,
    worry_denom: i64,
    use_mod: bool,
) -> Vec<usize> {
    let mut inspection_counter: Vec<usize> = vec![0; monkeys.len()];

    let denom: i64 = if use_mod {
        monkeys
            .iter()
            .map(|m| match m.cond {
                Cond::IfDivisibleBy(a, _, _) => a,
            })
            .product()
    } else {
        worry_denom
    };


    for _round in 0..n_rounds {
        for mi in 0..monkeys.len() {
            while let Some(item) = monkeys[mi].inspect(denom, use_mod) {
                let target = monkeys[mi].test(item);
                monkeys[target].receive(item);

                inspection_counter[mi] += 1;
            }
        }
    }

    inspection_counter.sort();
    inspection_counter
}

fn parse_cond(c: &str, t: &str, f: &str) -> Cond {
    let c = c.split(" ").last().unwrap().parse::<i64>().unwrap();
    let t = t.split(" ").last().unwrap().parse::<usize>().unwrap();
    let f = f.split(" ").last().unwrap().parse::<usize>().unwrap();
    Cond::IfDivisibleBy(c, t, f)
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let mut monkeys = parse_input(_input);
        let inspection_counter = play_rounds(&mut monkeys, 20, 3, false);
        let answer = inspection_counter
            .iter()
            .rev()
            .take(2)
            .fold(1, |acc, &n| acc * n);

        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let mut monkeys = parse_input(_input);
        let inspection_counter = play_rounds(&mut monkeys, 10000, 0, true);
        let answer = inspection_counter
            .iter()
            .rev()
            .take(2)
            .fold(1, |acc, &n| acc * n);

        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_INPUT: &str = "Monkey 0:
  Starting items: 79, 98
  Operation: new = old * 19
  Test: divisible by 23
    If true: throw to monkey 2
    If false: throw to monkey 3

Monkey 1:
  Starting items: 54, 65, 75, 74
  Operation: new = old + 6
  Test: divisible by 19
    If true: throw to monkey 2
    If false: throw to monkey 0

Monkey 2:
  Starting items: 79, 60, 97
  Operation: new = old * old
  Test: divisible by 13
    If true: throw to monkey 1
    If false: throw to monkey 3

Monkey 3:
  Starting items: 74
  Operation: new = old + 3
  Test: divisible by 17
    If true: throw to monkey 0
    If false: throw to monkey 1
";

    #[test]
    fn test_day11a() {
        let solver = Solution {};
        assert_eq!(solver.part1(TEST_INPUT).unwrap(), "10605");
    }
    #[test]
    fn test_day11b() {
        let solver = Solution {};
        assert_eq!(solver.part2(TEST_INPUT).unwrap(), "2713310158");
    }
}
