use std::{
    collections::{HashMap, HashSet, VecDeque},
    fmt::Display,
    ops::{Add, Mul, Sub},
};

use crate::problem::Problem;
use regex::Regex;

pub struct Solution {}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
enum Material {
    Ore,
    Clay,
    Obsidian,
    Geode,
}

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
struct Resources {
    ore: isize,
    clay: isize,
    obsidian: isize,
    geode: isize,
}

type Production = Resources;

impl Resources {
    fn new(ore: isize, clay: isize, obsidian: isize, geode: isize) -> Self {
        Self {
            ore,
            clay,
            obsidian,
            geode,
        }
    }

    fn scalar_multiply(&self, scalar: isize) -> Resources {
        Self {
            ore: self.ore * scalar,
            clay: self.clay * scalar,
            obsidian: self.obsidian * scalar,
            geode: self.geode * scalar,
        }
    }

    fn add_production(&self, material: Material) -> Resources {
        let mut new_production = self.clone();
        match material {
            Ore => new_production.ore += 1,
            Clay => new_production.clay += 1,
            Obsidian => new_production.obsidian += 1,
            Geode => new_production.geode += 1,
        }

        new_production
    }
}

impl Add for Resources {
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        Self {
            ore: self.ore + rhs.ore,
            clay: self.clay + rhs.clay,
            obsidian: self.obsidian + rhs.obsidian,
            geode: self.geode + rhs.geode,
        }
    }
}

impl Sub for Resources {
    type Output = Self;

    fn sub(self, rhs: Self) -> Self::Output {
        Self {
            ore: self.ore - rhs.ore,
            clay: self.clay - rhs.clay,
            obsidian: self.obsidian - rhs.obsidian,
            geode: self.geode - rhs.geode,
        }
    }
}

use Material::*;

#[derive(Debug)]
struct Blueprint {
    id: isize,
    ore_robot_cost: Resources,
    clay_robot_cost: Resources,
    obsidian_robot_costs: Resources,
    geode_robot_costs: Resources,
}

impl Blueprint {
    fn from_str(input: &str) -> Self {
        let re = Regex::new(r"(?P<num>[-\d]*)").unwrap();
        let c = re
            .captures_iter(input)
            .filter_map(|digits| digits["num"].parse().ok())
            .collect::<Vec<isize>>();

        Blueprint {
            id: c[0],
            ore_robot_cost: Resources::new(c[1], 0, 0, 0),
            clay_robot_cost: Resources::new(c[2], 0, 0, 0),
            obsidian_robot_costs: Resources::new(c[3], c[4], 0, 0),
            geode_robot_costs: Resources::new(c[5], 0, c[6], 0),
        }
    }

    fn get_cost(&self, material: Material) -> Resources {
        match material {
            Ore => self.ore_robot_cost,
            Clay => self.clay_robot_cost,
            Obsidian => self.obsidian_robot_costs,
            Geode => self.geode_robot_costs,
        }
    }

    fn can_build(&self, material: Material, resources: &Resources) -> bool {
        match material {
            Ore => resources.ore >= self.ore_robot_cost.ore,
            Clay => resources.ore >= self.clay_robot_cost.ore,
            Obsidian => {
                resources.ore >= self.obsidian_robot_costs.ore
                    && resources.clay >= self.obsidian_robot_costs.clay
            }
            Geode => {
                resources.ore >= self.geode_robot_costs.ore
                    && resources.obsidian >= self.geode_robot_costs.obsidian
            }
        }
    }
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
struct State {
    time: isize,
    resources: Resources,
    production: Production,
}

enum Buildable {
    Now(Resources, Production),
    Future(isize),
    Never,
}

use Buildable::*;

impl State {
    fn new(time: isize) -> Self {
        Self {
            time,
            resources: Resources::new(0, 0, 0, 0),
            production: Production::new(1, 0, 0, 0),
        }
    }

    fn time_to(cost: isize, resource: isize, production: isize) -> isize {
        (cost - resource + production - 1) / production.max(0) + 1
    }

    fn time_until_buildable(&self, material: Material, blueprint: &Blueprint) -> isize {
        let cost = blueprint.get_cost(material);
        let dt = match material {
            Ore => {
                if self.production.ore > 0 {
                    (cost.ore - self.resources.ore) / self.production.ore
                } else {
                    0
                }
            }
            Clay => {
                if self.production.ore > 0 {
                    (cost.ore - self.resources.ore) / self.production.ore
                } else {
                    0
                }
            }
            Obsidian => {
                let left = cost - self.resources;
                let time_ore = if left.ore > 0 && self.production.ore > 0 {
                    left.ore / self.production.ore
                } else {
                    0
                };
                let time_clay = if left.clay > 0 && self.production.clay > 0 {
                    left.clay / self.production.clay
                } else {
                    0
                };

                if self.production.ore > 0 && self.production.clay > 0 {
                    time_ore.max(time_clay)
                } else if self.production.ore > 0 && left.clay == 0 {
                    time_ore
                } else if self.production.clay > 0 && left.ore == 0 {
                    time_clay
                } else {
                    0
                }
            }
            Geode => {
                let left = cost - self.resources;
                let time_ore = if left.ore > 0 && self.production.ore > 0 {
                    left.ore / self.production.ore
                } else {
                    0
                };
                let time_obsidian = if left.obsidian > 0 && self.production.obsidian > 0 {
                    left.obsidian / self.production.obsidian
                } else {
                    0
                };

                if self.production.ore > 0 && self.production.obsidian > 0 {
                    time_ore.max(time_obsidian)
                } else if self.production.ore > 0 && left.obsidian == 0 {
                    time_ore
                } else if self.production.obsidian > 0 && left.ore == 0 {
                    time_obsidian
                } else {
                    0
                }
            }
        };

        dt
    }

    fn can_build(&self, material: Material, blueprint: &Blueprint) -> Buildable {
        if blueprint.can_build(material, &self.resources) {
            let new_resources = self.resources - blueprint.get_cost(material);
            let new_production = self.production.add_production(material);
            Buildable::Now(new_resources, new_production)
        } else {
            let dt = self.time_until_buildable(material, &blueprint);
            if dt == 0 {
                Buildable::Never
            } else {
                Future(dt)
            }
        }
    }

    fn valid_futures(&self, blueprint: &Blueprint) -> Vec<State> {
        [Ore, Clay, Obsidian, Geode]
            .iter()
            .flat_map(|&robot_type| match self.can_build(robot_type, &blueprint) {
                Now(resources, production) => {
                    let new_resources = resources + self.production;
                    let state_built = State {
                        time: self.time - 1,
                        resources: new_resources,
                        production,
                    };
                    vec![state_built]
                }
                Future(t) => {
                    let new_resources =
                        self.resources + self.production.scalar_multiply(t as isize);
                    vec![State {
                        time: self.time - t as isize,
                        resources: new_resources,
                        production: self.production,
                    }]
                }
                Never => vec![],
            })
            .filter(|s| s.time > 0)
            .collect::<Vec<State>>()
    }
}

fn find_highest_geode_produced(state: State, blueprint: &Blueprint) -> isize {
    let mut visited: HashSet<State> = HashSet::new();
    let mut stack = VecDeque::new();
    stack.push_back(state);

    let mut best = 0;

    while let Some(s) = stack.pop_back() {
        if !visited.contains(&s) {
            best = best.max(s.resources.geode);
            let next_states = s.valid_futures(&blueprint);
            visited.insert(s);
            for future_state in next_states {
                if !stack.contains(&future_state) {
                    stack.push_back(future_state)
                }
            }

            // Pretend to wait till the end
            if s.production.geode > 0 {
                best = best.max(s.production.geode * s.time + s.resources.geode);
            }
        }
    }
    best
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let time = 24;
        let state = State::new(time);
        let answer: isize = _input
            .lines()
            .map(|l| Blueprint::from_str(l))
            .map(|bp| {
                println!("Blueprint {}", &bp.id);
                let best = find_highest_geode_produced(state.clone(), &bp);
                bp.id * best
            })
            .sum();

        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        // Some(format!("{}", "undefined"))
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.
Blueprint 2: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 8 clay. Each geode robot costs 3 ore and 12 obsidian.";

    #[test]
    fn test_day19a() {
        let time = 24;
        let state = State::new(time);
        let answer: isize = INPUT
            .lines()
            .map(|l| Blueprint::from_str(l))
            .map(|bp| {
                let best = find_highest_geode_produced(state.clone(), &bp);
                bp.id * best
            })
            .sum();

        assert_eq!(answer, 33);
    }
}
