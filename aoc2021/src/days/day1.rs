use crate::problem::Problem;

pub struct Solution {}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let depths: Vec<i32> = input.split('\n').flat_map(|x| x.parse()).collect();
        let increases: i32 = depths.iter().zip(&depths[1..])
            .map(|(cur, next)| if next - cur > 0 {1} else {0})
            .sum();

        format!("{}", increases)
    }

    fn part2(&self, input: &str) -> String {
        let depths: Vec<i32> = input.split('\n').flat_map(|x| x.parse()).collect();
        let window_size = 3;
        let mut window: i32 = depths[0..window_size].iter().sum();

        let mut acc = 0;
        for i in 0..(depths.len() - window_size) {
            let new_window = window - depths[i] + depths[i+window_size];
            if new_window > window {
                acc += 1;
            }
                
            window = new_window;
        }

        format!("{}", acc)
    }
}
