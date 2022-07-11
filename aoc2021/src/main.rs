use std::fs;
use std::time::Instant;

mod problem;
use problem::Problem;
mod days;

pub fn main() {
    let day: usize = 5;
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
        1 => Some(Box::new(days::day1::DayOne {})),
        2 => Some(Box::new(days::day2::DayTwo {})),
        3 => Some(Box::new(days::day3::DayThree {})),
        4 => Some(Box::new(days::day4::DayFour {})),
        5 => Some(Box::new(days::day5::DayFive {})),
        6 => Some(Box::new(days::day6::DaySix {})),
        7 => Some(Box::new(days::day7::DaySeven {})),
        // ...
        _ => None,
    }
}

fn run(problem: &dyn Problem, day: usize, part: usize, input: &str) {
    let start = Instant::now();
    let output = match part {
        1 => problem.part1(input),
        2 => problem.part2(input),
        _ => "Error".to_string(),
    };
    let duration = start.elapsed();

    println!(
        "Answer to day {}, part {} ({}.{:03} s): {}",
        day,
        part,
        duration.as_secs(),
        duration.subsec_millis(),
        output
    );
}

fn get_input(day: usize) -> String {
    let filename = input_file_path(day);
    fs::read_to_string(filename).expect("Something went wrong reading the file")
}

fn input_file_path(day: usize) -> String {
    format!("inputs/{:02}.in", day)
}
