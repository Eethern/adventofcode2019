use std::fs;
use std::time::Instant;

mod problem;
use problem::Problem;
mod days;

pub fn main() {
    let day: usize = 1;
    let input: String = get_input(day);
    let problem = match_day(day);

    match problem {
        Some(x) => {
            run(&*x, day, 1, &input);
            run(&*x, day, 2, &input);
        }
        None => println!("Cannot find problem"),
    }
}

fn match_day(day: usize) -> Option<Box<dyn Problem>> {
    match day {
        1 => Some(Box::new(days::day01::Solution {})),
        // 2 => Some(Box::new(days::day02::Solution {})),
        // 3 => Some(Box::new(days::day03::Solution {})),
        // 4 => Some(Box::new(days::day04::Solution {})),
        // 5 => Some(Box::new(days::day05::Solution {})),
        // 6 => Some(Box::new(days::day06::Solution {})),
        // 7 => Some(Box::new(days::day07::Solution {})),
        // 8 => Some(Box::new(days::day08::Solution {})),
        // 9 => Some(Box::new(days::day09::Solution {})),
        // 10 => Some(Box::new(days::day10::Solution {})),
        // 11 => Some(Box::new(days::day11::Solution {})),
        // 12 => Some(Box::new(days::day12::Solution {})),
        // 13 => Some(Box::new(days::day13::Solution {})),
        // 14 => Some(Box::new(days::day14::Solution {})),
        // 15 => Some(Box::new(days::day15::Solution {})),
        // 16 => Some(Box::new(days::day16::Solution {})),
        // 17 => Some(Box::new(days::day17::Solution {})),
        // 18 => Some(Box::new(days::day18::Solution {})),
        // 19 => Some(Box::new(days::day19::Solution {})),
        // 20 => Some(Box::new(days::day20::Solution {})),
        // 21 => Some(Box::new(days::day21::Solution {})),
        // 22 => Some(Box::new(days::day22::Solution {})),
        // 23 => Some(Box::new(days::day23::Solution {})),
        // 24 => Some(Box::new(days::day24::Solution {})),
        // 25 => Some(Box::new(days::day25::Solution {})),
        _ => None,
    }
}

fn run(problem: &dyn Problem, day: usize, part: usize, input: &str) {
    let start = Instant::now();
    let output = match part {
        1 => problem.part1(input),
        2 => problem.part2(input),
        _ => None
    };
    let duration = start.elapsed();

    match output {
        Some(out) => {
            println!(
                "Answer to day {}, part {} ({}.{:06} s): {}",
                day,
                part,
                duration.as_secs(),
                duration.subsec_micros(),
                out
            )
        },
        None => ()
    };
}

fn get_input(day: usize) -> String {
    let filename = input_file_path(day);
    fs::read_to_string(filename).expect("Something went wrong reading the file")
}

fn input_file_path(day: usize) -> String {
    format!("inputs/{:02}.in", day)
}
