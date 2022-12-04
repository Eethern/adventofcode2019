use std::fs;
use std::time::{Duration, Instant};

mod problem;
use problem::Problem;
mod days;

#[derive(Debug)]
pub enum AOCError {
    SolutionNotFound,
    InputNotFound,
    NotImplemented,
}

pub fn main() {
    for day in 1..=25 {
        match run_day(day) {
            Ok(_) => (),
            Err(e) => println!("[DAY {:02}] {:?}", day, e),
        }
    }
}

fn run_day(day: usize) -> Result<bool, AOCError> {
    let input = get_input(day)?;
    let solver = get_solver(day)?;

    let start = Instant::now();
    let answer_part1 = solver.part1(&input);
    let time_part1 = start.elapsed();
    println!("{}", format_answer(day, 'a', time_part1, answer_part1));

    let start = Instant::now();
    let answer_part2 = solver.part2(&input);
    let time_part2 = start.elapsed();
    println!("{}", format_answer(day, 'b', time_part2, answer_part2));

    Ok(true)
}

fn format_answer(day: usize, part: char, time: Duration, answer: Option<String>) -> String {
    match answer {
        Some(answer) => format!(
            "[DAY {:02}{}] {:6} µs: {}",
            day,
            part,
            time.subsec_micros(),
            answer,
        ),
        None => format!("[DAY {:02}{}] {:?}", day, part, AOCError::NotImplemented),
    }
}

macro_rules! load_solver {
    ($day:ident) => {
        Ok(Box::new(days::$day::Solution {}))
    };
}

fn get_solver(day: usize) -> Result<Box<dyn Problem>, AOCError> {
    match day {
        1 => load_solver!(day01),
        2 => load_solver!(day02),
        3 => load_solver!(day03),
        4 => load_solver!(day04),
        5 => load_solver!(day05),
        6 => load_solver!(day06),
        7 => load_solver!(day07),
        8 => load_solver!(day08),
        9 => load_solver!(day09),
        10 => load_solver!(day10),
        11 => load_solver!(day11),
        12 => load_solver!(day12),
        13 => load_solver!(day13),
        14 => load_solver!(day14),
        15 => load_solver!(day15),
        16 => load_solver!(day16),
        17 => load_solver!(day17),
        18 => load_solver!(day18),
        19 => load_solver!(day19),
        20 => load_solver!(day20),
        21 => load_solver!(day21),
        22 => load_solver!(day22),
        23 => load_solver!(day23),
        24 => load_solver!(day24),
        25 => load_solver!(day25),
        _ => Err(AOCError::SolutionNotFound),
    }
}

fn get_input(day: usize) -> Result<String, AOCError> {
    let filename = input_file_path(day);
    match fs::read_to_string(filename) {
        Ok(input) => Ok(input),
        Err(_) => Err(AOCError::InputNotFound),
    }
}

fn input_file_path(day: usize) -> String {
    format!("inputs/{:02}.in", day)
}
