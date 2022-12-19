use std::collections::{HashMap};

use regex::Regex;

use crate::problem::Problem;

pub struct Solution {}

const TIME: i32 = 30;
const TIME_TO_OPEN: i32 = 1;
const TIME_TO_MOVE: i32 = 1;
const TIME_TO_TEACH: i32 = 4;

#[derive(Debug)]
struct Valve {
    name: String,
    rate: i32,
    edges: Vec<String>,
}

#[derive(Clone, Eq, PartialEq, Hash)]
struct State {
    open: Vec<String>,
    elephant_pos: String,
    you_pos: String,
    time_left: i32,
}

impl State {
    fn new() -> Self {
        Self {
            open: vec![],
            elephant_pos: "AA".to_string(),
            you_pos: "AA".to_string(),
            time_left: TIME,
        }
    }

}

fn parse_input_to_valves(input: &str) -> Vec<Valve> {
    let re = Regex::new(
        r"Valve (?P<name>[A-Z]+) has flow rate=(?P<rate>[0-9]+); tunnels? leads? to valves? (?P<edges>.*)"
    ).unwrap();

    input
        .lines()
        .map(|l| re.captures(l).unwrap())
        .map(|obj| Valve {
            name: obj["name"].to_string(),
            rate: obj["rate"].parse().unwrap(),
            edges: obj["edges"]
                .split(", ")
                .map(|s| s.to_string())
                .collect::<Vec<String>>(),
        })
        .collect()
}

fn build_graph(valves: &Vec<Valve>) -> (HashMap<String, Vec<String>>, HashMap<String, i32>) {
    let flow = valves
        .iter()
        .map(|v| (v.name.clone(), v.rate))
        .collect::<HashMap<String, i32>>();

    let graph = valves
        .iter()
        .map(|v| (v.name.clone(), v.edges.clone()))
        .collect::<HashMap<String, Vec<String>>>();

    (graph, flow)
}

fn score(result: i32, time_left: i32, flow: i32) -> i32 {
    result + flow * (time_left - 1) 
}

fn dfs2(state: &mut State, graph: &HashMap<String, Vec<String>>, flows: &HashMap<String, i32>, cache: &mut HashMap<State, i32>) -> i32 {
    // Recursion base case
    if state.time_left <= 0 {
        return 0;
    }

    // Memoization
    if let Some(&answer) = cache.get(state) {
        return answer;
    }

    // elephant
    let mut best = i32::MIN;
    let pos = &state.elephant_pos;
    let flow = *flows.get(pos).unwrap();
    if flow > 0 && !state.open.contains(&pos) {
        graph.get(pos).unwrap().iter().for_each(|child| {
            let mut new_state = state.clone();
            new_state.open.push(pos.clone());
            new_state.elephant_pos = child.clone();
            new_state.time_left -= TIME_TO_MOVE + TIME_TO_OPEN;
            let result = dfs2(&mut new_state, graph, flows, cache);
            best = best.max(score(result, new_state.time_left, flow));
        });
    }

    // Just move
    graph.get(pos).unwrap().iter().for_each(|child| {
        let mut new_state = state.clone();
        new_state.time_left -= TIME_TO_MOVE;
        new_state.elephant_pos = child.clone();
        let result = dfs2(state, graph, flows, cache);
        best = best.max(result);
    });


    let pos = state.elephant_pos.clone();
    let flow = *flows.get(&pos).unwrap();
    if flow > 0 && !state.open.contains(&pos) {
        graph.get(&pos).unwrap().iter().for_each(|child| {
            let mut new_state = state.clone();
            new_state.open.push(pos.clone());
            new_state.elephant_pos = child.clone();
            new_state.time_left -= TIME_TO_MOVE + TIME_TO_OPEN;
            let result = dfs2(&mut new_state, graph, flows, cache);
            best = best.max(score(result, new_state.time_left, flow));
        });
    }

    // Just move
    graph.get(&pos).unwrap().iter().for_each(|child| {
        let mut new_state = state.clone();
        new_state.time_left -= TIME_TO_MOVE;
        new_state.elephant_pos = child.clone();
        let result = dfs2(state, graph, flows, cache);
        best = best.max(result);
    });

    cache.insert(state.clone(), best);
    best
}

fn dfs(
    node: &str,
    path: &mut Vec<String>,
    graph: &HashMap<String, Vec<String>>,
    flows: &HashMap<String, i32>,
    time_left: i32,
    cache: &mut HashMap<(String, Vec<String>, i32), i32>
) -> i32 {
    // Exit
    if time_left <= 0 {
        return 0;
    }

    // memoization
    if let Some(&answer) = cache.get(&(node.to_string(), path.clone(), time_left)) {
        return answer;
    }

    let mut best = i32::MIN;

    // Open the valve
    if *flows.get(node).unwrap() > 0 && !path.contains(&node.to_string()) {
        graph.get(node).unwrap().iter().for_each(|child| {
            path.push(node.to_string());

            let result = dfs(&child, path, graph, flows, time_left - TIME_TO_MOVE - TIME_TO_OPEN, cache);

            best = best.max(score(result, time_left, *flows.get(node).unwrap()));

            path.pop();
        });
    }
    
    // Just move
    graph.get(node).unwrap().iter().for_each(|child| {
        let result = dfs(child, path, graph, flows, time_left-TIME_TO_MOVE, cache);
        best = best.max(result);
    });

    cache.insert((node.to_string(), path.clone(), time_left), best);
    best
}


impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let valves = parse_input_to_valves(_input);
        let (graph, flows) = build_graph(&valves);
        let mut cache = HashMap::new();
        let mut path = vec![];

        let answer = dfs("AA", &mut path, &graph, &flows, TIME, &mut cache);
        
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let valves = parse_input_to_valves(_input);
        let (graph, flows) = build_graph(&valves);
        let mut cache = HashMap::new();

        let mut state = State::new();
        state.time_left -= TIME_TO_TEACH;

        let answer = dfs2(&mut state, &graph, &flows, &mut cache);

        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
Valve BB has flow rate=13; tunnels lead to valves CC, AA
Valve CC has flow rate=2; tunnels lead to valves DD, BB
Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
Valve EE has flow rate=3; tunnels lead to valves FF, DD
Valve FF has flow rate=0; tunnels lead to valves EE, GG
Valve GG has flow rate=0; tunnels lead to valves FF, HH
Valve HH has flow rate=22; tunnel leads to valve GG
Valve II has flow rate=0; tunnels lead to valves AA, JJ
Valve JJ has flow rate=21; tunnel leads to valve II
";
    #[test]
    fn test_day16a() {
        let solution = Solution {};
        let answer = solution.part1(INPUT).unwrap();
        
        assert_eq!(answer, "1651");
    }

    #[test]
    #[ignore]
    fn test_day16b() {
        let solution = Solution {};
        let answer = solution.part2(INPUT).unwrap();
        
        assert_eq!(answer, "1707");
    }
}
