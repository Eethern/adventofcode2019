use crate::problem::Problem;

pub struct Solution {}

struct Region {
    x0: isize,
    y0: isize,
    x1: isize,
    y1: isize,
}


impl Region {
    fn new(x0: isize, y0: isize, x1: isize, y1: isize) -> Region {
        Region { x0, y0, x1, y1 }
    }

    fn point_in_region(&self, x: isize, y: isize) -> bool {
        x >= self.x0 && x <= self.x1 && y >= self.y0 && y <= self.y1
    }
}

fn parse_target(input: &str) -> Region {
    let bounds: Vec<isize> = input.lines().next().unwrap()[13..]
        .split(", ")
        .flat_map(|s| {
            s[2..]
                .split("..")
                .map(|n| n.parse::<isize>().expect("could not parse target value"))
                .collect::<Vec<isize>>()
        })
        .collect();

    Region::new(bounds[0], bounds[2], bounds[1], bounds[3])
}

fn compute_initial_x_velocities(target: &Region) -> Vec<isize> {
    (0..target.x1 + 1).collect()
}

fn evaluate_candidate_trajectory(
    target: &Region,
    vx0: isize,
    vy0: isize,
) -> Option<((isize, isize), (isize, isize))> {
    let mut vy = vy0;
    let mut vx = vx0;
    let mut y = 0;
    let mut x = 0;
    let mut best = (isize::MIN, isize::MIN);
    loop {
        x += vx;
        y += vy;

        if y > best.1 {
            best = (x, y);
        }

        if target.point_in_region(x, y) {
            return Some((best, (vx0, vy0)));
        }

        // Assume going right down
        if x >= target.x1 || y < target.y0 {
            return None;
        }

        vy -= 1;
        vx -= vx.signum();
    }
}

fn get_optimal_initial_velocity(input: &str) -> ((isize, isize), (isize, isize)) {
    let target = parse_target(input);
    let vxs = compute_initial_x_velocities(&target);

    let mut best = ((isize::MIN, isize::MIN), (0, 0));
    for vx in vxs {
        let mut vy = target.y1;
        let mut iterations = 0;
        while (iterations + 1) / 2 < -target.y0 {
            best = match evaluate_candidate_trajectory(&target, vx, vy) {
                Some((p, v)) => {
                    if p.1 > best.0 .1 {
                        (p, v)
                    } else {
                        best
                    }
                }
                None => best,
            };

            vy += 1;
            iterations += 1;
        }
    }
    best
}

fn get_all_initial_velocities(input: &str) -> Vec<((isize, isize), (isize, isize))> {
    let target = parse_target(input);
    let vxs = compute_initial_x_velocities(&target);

    let mut candidates = vec![];
    for vx0 in vxs {
        let mut vy0 = target.y0;
        let mut iterations = 0;
        while ((iterations + 1) / 2 <= -target.y0)
            || (vy0 < 0 && (iterations <= -target.y0))
            || (vy0 == 0 && (iterations + 1) <= -target.y0)
        {
            if let Some(c) = evaluate_candidate_trajectory(&target, vx0, vy0) {
                candidates.push(c);
            }

            vy0 += 1;
            iterations += 1;
        }
    }
    candidates
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let highest_point = get_optimal_initial_velocity(input);
        format!("{}", highest_point.0 .1)
    }

    fn part2(&self, input: &str) -> String {
        let candidates = get_all_initial_velocities(input);
        format!("{}", candidates.len())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "target area: x=20..30, y=-10..-5";
        let (p, v) = get_optimal_initial_velocity(input);
        assert_eq!(45, p.1, "incorrect height");
        assert_eq!((6, 9), v, "incorrect velocity");
    }
    #[test]
    fn test_part2_example() {
        let input = "target area: x=20..30, y=-10..-5";
        let candidates = get_all_initial_velocities(input);
        assert_eq!(112, candidates.len(), "incorrect number of candidates");
    }
}

