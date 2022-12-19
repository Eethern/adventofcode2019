use crate::problem::Problem;
use itertools::Itertools;
use regex::Regex;

pub struct Solution {}

type Point = (isize, isize);

#[derive(Debug)]
struct Sensor {
    pos: Point,
    beacon_pos: Point,
    dist: isize,
}

impl Sensor {
    fn from_log(log: &str) -> Self {
        let re = Regex::new(r"[x|y]=(?P<num>[-\d]*)").unwrap();
        let c = re
            .captures_iter(log)
            .filter_map(|digits| digits["num"].parse().ok())
            .collect::<Vec<isize>>();

        Sensor {
            pos: (c[0], c[1]),
            beacon_pos: (c[2], c[3]),
            dist: manhattan(&(c[0], c[1]), &(c[2], c[3])),
        }
    }
}

fn manhattan((ax, ay): &Point, (bx, by): &Point) -> isize {
    (ax - bx).abs() + (ay - by).abs()
}

fn get_bounds(sensors: &Vec<Sensor>) -> Point {
    sensors.iter().fold((0, 0), |(l, r), s| {
        let l = if s.pos.0 - s.dist < l {
            s.pos.0 - s.dist
        } else {
            l
        };
        let r = if s.pos.1 + s.dist > r {
            s.pos.1 + s.dist
        } else {
            r
        };
        (l, r)
    })
}

fn check_coverage(point: &Point, sensors: &Vec<Sensor>) -> bool {
    sensors.iter().any(|s| {
        if s.beacon_pos == *point {
            true
        } else {
            // get dist p->s
            let dist = manhattan(&point, &s.pos);
            // cmp dist with s.dist
            dist <= s.dist
        }
    })
}

fn parse_input(input: &str) -> Vec<Sensor> {
    input
        .lines()
        .map(|l| Sensor::from_log(l))
        .collect::<Vec<Sensor>>()
}

fn count_covered_positions(input: &str, y: isize) -> isize {
    let sensors = parse_input(input);
    let (x0, x1) = get_bounds(&sensors);

    (x0..=x1).fold(0, |acc, x| {
        acc + if check_coverage(&(x, y), &sensors) {
            1
        } else {
            0
        }
    }) - 1
}

fn good_sensor_pair(s1: &Sensor, s2: &Sensor) -> bool {
    manhattan(&s1.pos, &s2.pos) == s1.dist + s2.dist + 2
}

fn get_candidates(sensors: &Vec<Sensor>, bounds: (isize, isize)) -> Vec<Point> {
    sensors
        .iter()
        .cartesian_product(sensors.iter())
        .filter(|(s1, s2)| good_sensor_pair(s1, s2))
        .flat_map(|(s1, _)| {
            let (x, y) = s1.pos;
            let dist = s1.dist + 1;
            (x..x + dist)
                .zip((y..y + dist).rev())
                .chain((x..x + dist).zip(y - dist..y))
                .chain((x - dist..x).zip(y..y + dist))
                .chain((x - dist..x).zip((y - dist..y).rev()))
                .filter(|(x, y)| {
                    (bounds.0..bounds.1).contains(x) && (bounds.0..bounds.1).contains(y)
                })
                .collect::<Vec<Point>>()
        })
        .collect::<Vec<Point>>()
}

// fn get_candidates2(sensors: &Vec<Sensor>, (min, max): (isize, isize)) -> Vec<Point> {
//     sensors
//         .iter()
//         .flat_map(|s| {
//             let p1 = (s.dist - s.pos.1.abs(), s.dist - s.pos.0.abs());
//             let p2 = (-s.dist + s.pos.1.abs(), s.dist - s.pos.0.abs());
//             let p3 = (s.dist - s.pos.1.abs(), -s.dist + s.pos.0.abs());
//             let p4 = (-s.dist + s.pos.1.abs(), -s.dist + s.pos.0.abs());
//             vec![p1, p2, p3, p4]
//         })
//         .filter(|(x, y)| (min..max).contains(x) && (min..max).contains(y))
//         .collect::<Vec<Point>>()
// }

fn pinpoint_beacon(input: &str, (min, max): Point) -> Point {
    let sensors = parse_input(input);

    *get_candidates(&sensors, (min, max))
        .iter()
        .find(|&p| !(check_coverage(&p, &sensors)))
        .unwrap()
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let answer = count_covered_positions(_input, 2000000);
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let (min, max) = (0, 4000000);
        let (x, y) = pinpoint_beacon(_input, (min, max));
        let answer = x * 4000000 + y;
        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "Sensor at x=2, y=18: closest beacon is at x=-2, y=15
Sensor at x=9, y=16: closest beacon is at x=10, y=16
Sensor at x=13, y=2: closest beacon is at x=15, y=3
Sensor at x=12, y=14: closest beacon is at x=10, y=16
Sensor at x=10, y=20: closest beacon is at x=10, y=16
Sensor at x=14, y=17: closest beacon is at x=10, y=16
Sensor at x=8, y=7: closest beacon is at x=2, y=10
Sensor at x=2, y=0: closest beacon is at x=2, y=10
Sensor at x=0, y=11: closest beacon is at x=2, y=10
Sensor at x=20, y=14: closest beacon is at x=25, y=17
Sensor at x=17, y=20: closest beacon is at x=21, y=22
Sensor at x=16, y=7: closest beacon is at x=15, y=3
Sensor at x=14, y=3: closest beacon is at x=15, y=3
Sensor at x=20, y=1: closest beacon is at x=15, y=3";

    #[test]
    fn test_day15a() {
        let answer = count_covered_positions(INPUT, 10);
        assert_eq!(answer, 26);
    }

    #[test]
    fn test_day15b() {
        let (min, max) = (0, 20);
        let (x, y) = pinpoint_beacon(INPUT, (min, max));
        let answer = x * 4000000 + y;
        assert_eq!(answer, 56000011);
    }
}
