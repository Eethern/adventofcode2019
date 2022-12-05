use crate::problem::Problem;
use regex::Regex;
use std::collections::VecDeque;

pub struct Solution {}

type Instr = Vec<usize>;
type Lanes<T> = Vec<VecDeque<T>>;

fn parse_input(input: &str) -> (Lanes<&str>, Vec<Instr>) {
    let (lanes, instr) = input.split_once("\n\n").unwrap();
    let n_lanes = lanes
        .lines()
        .last()
        .unwrap()
        .chars()
        .fold(0, |acc, c| acc + !c.is_whitespace() as usize);
    (parse_lanes(lanes, n_lanes), parse_instr(instr))
}

fn parse_instr(input: &str) -> Vec<Instr> {
    let re = Regex::new(r"\w*\s(\d*)\s\w*\s(\w*)\s\w*\s(\d*)").unwrap();
    input
        .lines()
        .map(|l| {
            re.captures(l)
                .unwrap()
                .iter()
                .skip(1)
                .map(|m| m.unwrap().as_str().parse::<usize>().unwrap())
                .collect::<Instr>()
        })
        .collect::<Vec<Instr>>()
}

fn parse_lanes(input: &str, n_lanes: usize) -> Lanes<&str> {
    let re = Regex::new(r"(?:\[|\s)(?P<crate>([A-Z]|\s))(\]|\s)\s?").unwrap();
    let mut lanes = vec![VecDeque::new(); n_lanes];
    input.lines().rev().skip(1).for_each(|l| {
        re.captures_iter(l).enumerate().for_each(|(i, c)| {
            let c = c.name("crate").unwrap().as_str();
            if c != " " {
                lanes[i].push_back(c);
            }
        })
    });
    lanes
}

fn execute_9000(lanes: &mut Lanes<&str>, instr: Vec<Instr>) {
    for i in instr {
        assert!(i.len() == 3); // remove bounds checks
        let (num, from, to) = (i[0], i[1] - 1, i[2] - 1);
        for _ in 0..num {
            let elem = lanes[from].pop_back().unwrap();
            lanes[to].push_back(elem);
        }
    }
}

fn execute_9001(lanes: &mut Lanes<&str>, instr: Vec<Instr>) {
    let mut queue = VecDeque::new();
    for i in instr {
        assert!(i.len() == 3); // remove bounds checks
        let (num, from, to) = (i[0], i[1] - 1, i[2] - 1);
        for _ in 0..num {
            queue.push_back(lanes[from].pop_back().unwrap());
        }
        for _ in 0..num {
            lanes[to].push_back(queue.pop_back().unwrap());
        }
    }
}

fn get_tops(lanes: &Lanes<&str>) -> String {
    lanes.iter().map(|l| *l.back().unwrap()).collect()
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let (mut lanes, instr) = parse_input(_input);
        execute_9000(&mut lanes, instr);
        Some(get_tops(&lanes).to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let (mut lanes, instr) = parse_input(_input);
        execute_9001(&mut lanes, instr);
        Some(get_tops(&lanes).to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "    [D]    
[N] [C]    
[Z] [M] [P]
 1   2   3 

move 1 from 2 to 1
move 3 from 1 to 3
move 2 from 2 to 1
move 1 from 1 to 2
";

    #[test]
    fn test_day05a() {
        let (mut lanes, instr) = parse_input(INPUT);
        execute_9000(&mut lanes, instr);
        let answer = get_tops(&lanes);
        assert_eq!("CMZ", answer)
    }

    #[test]
    fn test_day05b() {
        let (mut lanes, instr) = parse_input(INPUT);
        execute_9001(&mut lanes, instr);
        let answer = get_tops(&lanes);
        assert_eq!("MCD", answer)
    }
}
