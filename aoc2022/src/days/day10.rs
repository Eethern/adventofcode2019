use std::fmt;

use itertools::Itertools;

use crate::problem::Problem;

pub struct Solution {}

#[derive(Copy, Clone)]
enum Opcode {
    NoOp,
    Add(i32),
}

impl Opcode {
    fn cycles(&self) -> usize {
        match self {
            Opcode::Add(_) => 2,
            Opcode::NoOp => 1,
        }
    }
}

struct CRTScreen {
    width: usize,
    height: usize,
    buffer: Vec<char>,
}

impl CRTScreen {
    fn new(width: usize, height: usize) -> Self {
        let buffer = vec!['.'; width * height];
        Self {
            width,
            height,
            buffer,
        }
    }
}

impl fmt::Display for CRTScreen {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let text = self
            .buffer
            .iter()
            .chunks(self.width)
            .into_iter()
            .map(|chunk| chunk.collect::<String>())
            .join("\n");

        write!(f, "{}", text)
    }
}

struct CPU {
    instructions: Vec<Opcode>,
    register_file: Vec<i32>,
    program_counter: usize,
    cycle_counter: usize,
    wait: usize,
}

impl CPU {
    fn new(instructions: Vec<Opcode>, n_registers: usize, initial_value: i32) -> Self {
        Self {
            instructions,
            register_file: vec![initial_value; n_registers],
            program_counter: 0,
            cycle_counter: 0,
            wait: 0,
        }
    }

    fn tick(&mut self) {
        let op = self.instructions[self.program_counter];
        if self.wait == op.cycles() {
            // execute
            self.execute_op(&op);
            self.program_counter += 1;
            self.wait = 0;
        }

        self.wait += 1;
        self.cycle_counter += 1;
    }

    fn get(&self, reg_index: usize) -> i32 {
        self.register_file[reg_index]
    }

    fn execute_op(&mut self, op: &Opcode) {
        match op {
            Opcode::Add(n) => self.register_file[0] += n,
            Opcode::NoOp => (),
        }
    }
}

fn parse_input(input: &str) -> Vec<Opcode> {
    input
        .lines()
        .map(|l| match l.split(" ").collect::<Vec<&str>>()[..] {
            ["addx", n] => Opcode::Add(n.parse().unwrap()),
            ["noop"] => Opcode::NoOp,
            _ => unreachable!(),
        })
        .collect()
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let instructions = parse_input(_input);
        let mut cpu = CPU::new(instructions, 1, 1);

        let mut answer = 0;
        for i in 0..40 * 6 {
            if (i - 20) % 40 == 0 {
                answer += i as i32 * cpu.get(0);
            }
            cpu.tick();
        }
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let instructions = parse_input(_input);
        let mut cpu = CPU::new(instructions, 1, 1);
        let mut display = CRTScreen::new(40, 6);

        let in_bounds = |c: i32, p| (p - 1) <= (c % 40) && (c % 40) <= (p + 1);

        for i in 0..40 * 6 {
            cpu.tick();
            if in_bounds(i as i32, cpu.get(0)) {
                display.buffer[i] = '#';
            }
        }
        Some(format!("\n{}", display))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_INPUT: &str = "addx 15
addx -11
addx 6
addx -3
addx 5
addx -1
addx -8
addx 13
addx 4
noop
addx -1
addx 5
addx -1
addx 5
addx -1
addx 5
addx -1
addx 5
addx -1
addx -35
addx 1
addx 24
addx -19
addx 1
addx 16
addx -11
noop
noop
addx 21
addx -15
noop
noop
addx -3
addx 9
addx 1
addx -3
addx 8
addx 1
addx 5
noop
noop
noop
noop
noop
addx -36
noop
addx 1
addx 7
noop
noop
noop
addx 2
addx 6
noop
noop
noop
noop
noop
addx 1
noop
noop
addx 7
addx 1
noop
addx -13
addx 13
addx 7
noop
addx 1
addx -33
noop
noop
noop
addx 2
noop
noop
noop
addx 8
noop
addx -1
addx 2
addx 1
noop
addx 17
addx -9
addx 1
addx 1
addx -3
addx 11
noop
noop
addx 1
noop
addx 1
noop
noop
addx -13
addx -19
addx 1
addx 3
addx 26
addx -30
addx 12
addx -1
addx 3
addx 1
noop
noop
noop
addx -9
addx 18
addx 1
addx 2
noop
noop
addx 9
noop
noop
noop
addx -1
addx 2
addx -37
addx 1
addx 3
noop
addx 15
addx -21
addx 22
addx -6
addx 1
noop
addx 2
addx 1
noop
addx -10
noop
noop
addx 20
addx 1
addx 2
addx 2
addx -6
addx -11
noop
noop
noop
";

    #[test]
    fn test_day10a() {
        let solver = Solution {};
        assert_eq!(solver.part1(TEST_INPUT).unwrap(), "13140");
    }
    #[test]
    fn test_day10b() {
        let solver = Solution {};
        let answer = solver.part2(TEST_INPUT).unwrap();

        let expected = "
##..##..##..##..##..##..##..##..##..##..
###...###...###...###...###...###...###.
####....####....####....####....####....
#####.....#####.....#####.....#####.....
######......######......######......####
#######.......#######.......#######.....";
        assert_eq!(answer, expected);
    }
}
