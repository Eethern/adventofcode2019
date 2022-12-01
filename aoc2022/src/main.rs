use std::fs;
use std::time::Instant;

mod problem;
use problem::Problem;
mod days;

pub fn main() {
    for day in 1..=25 {
        let input = match get_input(day) {
            Err(_) => {
                println!("[DAY {:02}] no input", day);
                continue;
            }
            Ok(input) => input,
        };

        match match_day(day) {
            Some(x) => {
                run(&*x, day, 1, &input);
                run(&*x, day, 2, &input);
            }
            None => println!("[DAY {:02}] no solution found", day),
        }
    }
}

macro_rules! load_solution {
    ($day:ident) => {
        Some(Box::new(days::$day::Solution {}))
    };
}

fn match_day(day: usize) -> Option<Box<dyn Problem>> {
    match day {
        1 => load_solution!(day01),
        2 => load_solution!(day02),
        3 => load_solution!(day03),
        4 => load_solution!(day04),
        5 => load_solution!(day05),
        6 => load_solution!(day06),
        7 => load_solution!(day07),
        8 => load_solution!(day08),
        9 => load_solution!(day09),
        10 => load_solution!(day10),
        11 => load_solution!(day11),
        12 => load_solution!(day12),
        13 => load_solution!(day13),
        14 => load_solution!(day14),
        15 => load_solution!(day15),
        16 => load_solution!(day16),
        17 => load_solution!(day17),
        18 => load_solution!(day18),
        19 => load_solution!(day19),
        20 => load_solution!(day20),
        21 => load_solution!(day21),
        22 => load_solution!(day22),
        23 => load_solution!(day23),
        24 => load_solution!(day24),
        25 => load_solution!(day25),
        _ => None,
    }
}

fn run(problem: &dyn Problem, day: usize, part: usize, input: &str) {
    let start = Instant::now();
    let output = match part {
        1 => problem.part1(input),
        2 => problem.part2(input),
        _ => None,
    };
    let duration = start.elapsed();

    match output {
        Some(out) => {
            println!(
                "[DAY {:02}] part {} ({}.{:06} s): {}",
                day,
                part,
                duration.as_secs(),
                duration.subsec_micros(),
                out
            )
        }
        None => (),
    };
}

fn get_input(day: usize) -> Result<String, std::io::Error> {
    let filename = input_file_path(day);
    fs::read_to_string(filename)
}

fn input_file_path(day: usize) -> String {
    format!("inputs/{:02}.in", day)
}
