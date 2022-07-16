use crate::problem::Problem;
use std::collections::VecDeque;

pub struct Solution {}

#[derive(Debug)]
struct Fish {
    timer: u32,
}

impl Fish {
    fn new(timer: u32) -> Self {
        Fish { timer }
    }
}

#[derive(Debug)]
struct Simulation {
    fishes: Vec<Fish>,
}

impl Simulation {
    fn new(input: &str) -> Self {
        let fishes: Vec<Fish> = input
            .strip_suffix('\n')
            .unwrap()
            .split(',')
            .map(|timer| Fish::new(timer.parse().unwrap()))
            .collect();
        Simulation { fishes }
    }

    fn tick(&mut self) {
        let mut new_fishes: Vec<Fish> = Vec::new();
        for fish in self.fishes.iter_mut() {
            // Handle births
            if fish.timer == 0 {
                fish.timer = 7;
                new_fishes.push(Fish::new(8))
            }

            // Update timer
            fish.timer -= 1
        }

        self.fishes.extend(new_fishes);
    }

    fn run(&mut self, iterations: usize) {
        for _ in 0..iterations {
            self.tick()
        }
    }
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        // Slow, memory inefficient solution
        let mut sim = Simulation::new(input);
        sim.run(80);

        format!("{}", sim.fishes.len())
    }

    fn part2(&self, input: &str) -> String {
        // Realize mistake, use cyclic buffer
        let sim = Simulation::new(input);
        let time = 256;

        let mut fish_counts: VecDeque::<u64> = VecDeque::from([0; 9]);
        for fish in sim.fishes {
            fish_counts[fish.timer as usize] += 1;
        }

        for _ in 0..time {
            fish_counts[7] += fish_counts[0];
            fish_counts.rotate_left(1);
        }

        let population_size: u64 = fish_counts.iter().sum();
        
        format!("{}", population_size)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "3,4,3,1,2\n";
        let mut sim = Simulation::new(input);
        sim.run(18);
        assert_eq!(sim.fishes.len(), 26);
        sim.run(62);
        assert_eq!(sim.fishes.len(), 5934);
    }

}
