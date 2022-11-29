use crate::problem::Problem;
use std::fmt;
use std::ops::{Add, Sub};
use std::collections::HashSet;

pub struct Solution {}

#[derive(Copy, Clone, Eq, Hash)]
struct Point3 {
    x: isize,
    y: isize,
    z: isize,
}

impl Point3 {
    fn new(x: isize, y: isize, z: isize) -> Point3 {
        Point3 { x, y, z }
    }
}

#[derive(Debug)]
enum Rot {
    I,
    X,
    Y,
    Z
}

// All 24 uniqu chains of 90 rotations of a 3D cube
// src: https://stackoverflow.com/a/50546727
const ROTATION_MAP: [[Rot; 4]; 24] = [
    [Rot::I,Rot::I,Rot::I,Rot::I],
    [Rot::X,Rot::I,Rot::I,Rot::I],
    [Rot::Y,Rot::I,Rot::I,Rot::I],
    [Rot::Z,Rot::I,Rot::I,Rot::I],
    [Rot::X,Rot::X,Rot::I,Rot::I],
    [Rot::X,Rot::Y,Rot::I,Rot::I],
    [Rot::X,Rot::Z,Rot::I,Rot::I],
    [Rot::Y,Rot::X,Rot::I,Rot::I],
    [Rot::Y,Rot::Y,Rot::I,Rot::I],
    [Rot::Z,Rot::Y,Rot::I,Rot::I],
    [Rot::Z,Rot::Z,Rot::I,Rot::I],
    [Rot::X,Rot::X,Rot::X,Rot::I],
    [Rot::X,Rot::X,Rot::Y,Rot::I],
    [Rot::X,Rot::X,Rot::Z,Rot::I],
    [Rot::X,Rot::Y,Rot::X,Rot::I],
    [Rot::X,Rot::Y,Rot::Y,Rot::I],
    [Rot::X,Rot::Z,Rot::Z,Rot::I],
    [Rot::Y,Rot::X,Rot::X,Rot::I],
    [Rot::Y,Rot::Y,Rot::Y,Rot::I],
    [Rot::Z,Rot::Z,Rot::Z,Rot::I],
    [Rot::X,Rot::X,Rot::X,Rot::Y],
    [Rot::X,Rot::X,Rot::Y,Rot::X],
    [Rot::X,Rot::Y,Rot::X,Rot::X],
    [Rot::X,Rot::Y,Rot::Y,Rot::Y]];

impl fmt::Debug for Point3 {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Point3[{}, {}, {}]", self.x, self.y, self.z)
    }
}

impl Add for Point3 {
    type Output = Self;
    fn add(self, other: Self) -> Self {
        Self {
            x: self.x + other.x,
            y: self.y + other.y,
            z: self.z + other.z,

        }
    }
}

impl Sub for Point3 {
    type Output = Self;
    fn sub(self, other: Self) -> Self {
        Self {
            x: self.x - other.x,
            y: self.y - other.y,
            z: self.z - other.z,

        }
    }
}

impl Point3 {
    fn rotate_x(&mut self) {
        let y = self.y;
        self.y = -self.z;
        self.z = y;
    }
    fn rotate_y(&mut self) {
        let z = self.z;
        self.z = self.x;
        self.x = -z;
    }
    fn rotate_z(&mut self) {
        let y = self.y;
        self.y = self.x;
        self.x = -y;
    }
    fn rotate(&mut self, rot: &[Rot]) {
        for r in rot {
            match r {
                Rot::I => break,
                Rot::X => self.rotate_x(),
                Rot::Y => self.rotate_y(),
                Rot::Z => self.rotate_z()
            }
        }
    }

    fn dist(&self, o: &Point3) -> isize {
        (self.x - o.x).pow(2) + (self.x-o.x).pow(2) + (self.x-o.x).pow(2)
    }
}

impl PartialEq for Point3 {
    fn eq(&self, other: &Self) -> bool {
        self.x == other.x && self.y == other.y && self.z == other.z
    }
}


#[derive(Debug, Clone)]
struct Scanner {
    id: usize,
    position: Point3,
    rotation: Point3,
    n_beacons: usize,
    relative_beacons: Vec<Point3>,
    aligned: bool,
}

impl Scanner {
    fn rotate(&mut self, rot: &[Rot]) {
        self.relative_beacons.iter_mut().for_each(|p| p.rotate(rot));
    }

    fn compute_inter_beacon_distances(&self) -> Vec<Point3> {
        self.relative_beacons.iter().flat_map(|p| {
            self.relative_beacons.iter().map(move |t| *p - *t)
        }).collect()
    }

    fn count_beacon_overlaps(&self, other: &Scanner) -> usize {
        let set: HashSet<Point3> = HashSet::from_iter(self.compute_inter_beacon_distances().iter().cloned());
        let mut points = HashSet::new();

        for beacon in other.relative_beacons.iter() {
            for target in other.relative_beacons.iter() {
                if set.contains(&(beacon.clone() - target.clone())) {
                    points.replace(beacon);
                    points.replace(target);
                }
            }
        }

        points.len() / 2

        // let set: HashSet<&Point3> = HashSet::from_iter(self.relative_beacons.iter());
        // other.relative_beacons.iter().fold(0, |acc, p| acc + if set.contains(p) {1} else {0})
    }

    fn align(&mut self, other: &Scanner) -> bool {
        // Try all rotations
        for r in ROTATION_MAP {
            let mut copy = self.clone();
            copy.rotate(&r);
            let n_overlaps = copy.count_beacon_overlaps(&other);
            if n_overlaps > 0 {
                dbg!(n_overlaps);
            }
            if n_overlaps >= 12 {
                self.rotate(&r);
                return true
            }
        }
        false
    }
}

fn align_scanners(scanners: &mut Vec<Scanner>) {
    // Fix origin
    scanners[0].aligned = true;
    let mut last_aligned = 0;
    let n_scanners = scanners.len();
    let mut n_aligned = 1;

    while n_aligned < n_scanners {
        for i in 1..n_scanners {
            // Align pairs of scanners
            if scanners[i].aligned || i == last_aligned {
                continue
            }

            let last_aligned_scanner = &scanners[last_aligned].clone();
            if scanners[i].align(last_aligned_scanner) {
                println!("aligned {} to {}", &scanners[i].id, &scanners[last_aligned].id);
                last_aligned = i;
                scanners[i].aligned = true;
                n_aligned += 1;
            }

        }
    }
}

fn parse_report(full_report: &str) -> Vec<Scanner> {
    full_report
        .split("\n\n")
        .map(|report| {
            let id = report
                .lines()
                .next()
                .unwrap()
                .split(' ')
                .nth(2)
                .unwrap()
                .parse::<usize>()
                .expect("could not parse scanner id");

            let position = Point3::new(0,0,0);
            let rotation = Point3::new(0,0,0);
            
            let relative_beacons: Vec<Point3> = report
                .lines()
                .skip(1)
                .map(|l| {
                    l.split(',')
                        .map(|n| n.parse::<isize>().expect("expected isize number"))
                        .collect()
                })
                .map(|v: Vec<isize>| Point3::new(v[0], v[1], v[2]))
                .collect();

            let n_beacons = relative_beacons.len();
            Scanner {
                id,
                position,
                rotation,
                n_beacons,
                relative_beacons,
                aligned: false,
            }
        })
        .collect()
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
//         let input = "--- scanner 0 ---
// -1,-1,1
// -2,-2,2
// -3,-3,3
// -2,-3,1
// 5,6,-4
// 8,0,7

// --- scanner 1 ---
// 1,-1,1
// 2,-2,2
// 3,-3,3
// 2,-1,3
// -5,4,-6
// -8,-7,0

// --- scanner 2 ---
// -1,-1,-1
// -2,-2,-2
// -3,-3,-3
// -1,-3,-2
// 4,6,5
// -7,0,8

// --- scanner 3 ---
// 1,1,-1
// 2,2,-2
// 3,3,-3
// 1,3,-2
// -4,-6,5
// 7,0,8

// --- scanner 4 ---
// 1,1,1
// 2,2,2
// 3,3,3
// 3,1,2
// -6,-4,-5
// 0,7,-8";
        let mut scanners = parse_report(input);
        align_scanners(&mut scanners);
        format!("{}", "undefined")
    }

    fn part2(&self, input: &str) -> String {
        format!("{}", "undefined")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore]
    fn test_name() {
        let input = "--- scanner 0 ---
-1,-1,1
-2,-2,2
-3,-3,3
-2,-3,1
5,6,-4
8,0,7

--- scanner 1 ---
1,-1,1
2,-2,2
3,-3,3
2,-1,3
-5,4,-6
-8,-7,0

--- scanner 2 ---
-1,-1,-1
-2,-2,-2
-3,-3,-3
-1,-3,-2
4,6,5
-7,0,8

--- scanner 3 ---
1,1,-1
2,2,-2
3,3,-3
1,3,-2
-4,-6,5
7,0,8

--- scanner 4 ---
1,1,1
2,2,2
3,3,3
3,1,2
-6,-4,-5
0,7,-8";

        let mut scanners = parse_report(input);
        align_scanners(&mut scanners);
    }
}
