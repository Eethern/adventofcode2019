use crate::problem::Problem;
use counter::Counter;
use std::collections::HashMap;

pub struct Solution {}

type BurnFunction<'a> = &'a dyn Fn(i32, i32, usize) -> usize;

fn parse_input(input: &str) -> Vec<i32> {
    input
        .strip_suffix('\n')
        .unwrap()
        .split(',')
        .map(|x| x.parse::<i32>().unwrap())
        .collect::<Vec<i32>>()
}

fn constant_fuel_burn_cost(target: i32, pos: i32, count: usize) -> usize {
    ((target - pos).unsigned_abs() as usize) * count
}

fn growing_fuel_burn_cost(target: i32, pos: i32, count: usize) -> usize {
    let dx = (target - pos).abs();
    ((dx * (dx + 1) / 2) as usize) * count
}

fn compute_cost(counts: &Counter<&i32>, target: i32, burn_fn: BurnFunction) -> usize {
    counts
        .iter()
        .map(|(&pos, count)| burn_fn(target, *pos, *count))
        .sum::<usize>()
}

fn optimize(positions: Vec<i32>, burn_fn: BurnFunction) -> (i32, usize) {
    let counts = positions.iter().collect::<Counter<_>>();
    let xmin = positions.iter().min().unwrap();
    let xmax = positions.iter().max().unwrap();
    let mut costs: HashMap<i32, usize> = HashMap::new();

    for target in *xmin..*xmax {
        let t = costs.entry(target).or_insert(0);
        *t = compute_cost(&counts, target, burn_fn);
    }

    let (&pos, &cost) = costs.iter().min_by_key(|entry| entry.1).unwrap();
    (pos, cost)
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let positions = parse_input(input);
        let (_, fuel) = optimize(positions, &constant_fuel_burn_cost);
        format!("{}", fuel)
    }

    fn part2(&self, input: &str) -> String {
        let positions = parse_input(input);
        let (_, fuel) = optimize(positions, &growing_fuel_burn_cost);
        format!("{}", fuel)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "16,1,2,0,4,2,7,1,2,14\n";
        let positions = parse_input(input);
        let (optimal, fuel) = optimize(positions, &constant_fuel_burn_cost);
        assert_eq!(optimal, 2);
        assert_eq!(fuel, 37);
    }

    #[test]
    fn test_part2_example() {
        let input = "16,1,2,0,4,2,7,1,2,14\n";
        let positions = parse_input(input);
        let (optimal, fuel) = optimize(positions, &growing_fuel_burn_cost);
        assert_eq!(optimal, 5);
        assert_eq!(fuel, 168);
    }
}
