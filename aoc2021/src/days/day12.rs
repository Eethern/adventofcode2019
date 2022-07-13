use crate::problem::Problem;
use std::collections::{HashMap, HashSet, VecDeque};

pub struct Solution {}

type AdjacencyList<'a> = HashMap<&'a str, Vec<&'a str>>;

fn create_adj_map(input: &str) -> AdjacencyList {
    let mut edges: HashMap<&str, Vec<&str>> = HashMap::new();
    for l in input.lines() {
        let (a, b) = l.split_once('-').unwrap();
        edges.entry(a).or_insert(vec![]).push(b);
        edges.entry(b).or_insert(vec![]).push(a);
    }
    edges
}

fn count_unique_paths(edges: &AdjacencyList, part2: bool) -> usize {
    let mut start = ("start", HashSet::from(["start"]), Option::None);
    let mut queue = VecDeque::from([start]);

    let mut paths = 0;
    loop {
        if queue.is_empty() {
            break;
        }

        let (name, small_set, twice) = queue.pop_front().unwrap();
        if name == "end" {
            paths += 1;
            continue;
        }

        for v in edges[name].iter() {
            if !small_set.contains(v) {
                let mut new_small_set = small_set.clone();
                if v.to_ascii_lowercase() == *v {
                    new_small_set.insert(v);
                }
                queue.push_back((v, new_small_set, twice));
            } else if small_set.contains(v)
                && twice == None
                && !["start", "end"].contains(v)
                && part2
            {
                queue.push_back((v, small_set.clone(), Some(*v)));
            }
        }
    }

    paths
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let edges = create_adj_map(input);
        let paths = count_unique_paths(&edges, false);

        format!("{}", paths)
    }

    fn part2(&self, input: &str) -> String {
        let edges = create_adj_map(input);
        let paths = count_unique_paths(&edges, true);

        format!("{}", paths)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
