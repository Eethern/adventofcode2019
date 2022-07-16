use crate::problem::Problem;
use std::cmp;

pub struct Solution {}

type Expr = Vec<(usize, u32)>;

fn parse_expr(expr: &str) -> Expr {
    expr.as_bytes().iter().fold((0, vec![]), |(mut d, mut numbers), b| {
        match b {
            b'[' => d += 1,
            b']' => d -= 1,
            b'0'..=b'9' => numbers.push((d, (b - b'0') as u32)),
            _ => {} 
        }
        (d, numbers)
    }).1
}

fn reduce_expr(expr: &mut Expr, prev_i: usize) {
    for i in prev_i..expr.len()-1 {
        if i == expr.len() {
            // Because we manipulate the list during iteration
            break;
        }
        let (d, l) = expr[i];
        if d == 5 {
            // explode
            let (_, r) = expr[i+1];
            expr.remove(i+1);
            if i != 0 {
                expr.get_mut(i-1).unwrap().1 += l;
            }
            if i != expr.len()-1 {
                expr.get_mut(i+1).unwrap().1 += r;
            }
            expr[i] = (4, 0);
            reduce_expr(expr, i) // restart
            
        }
    }
    for i in 0..expr.len() {
        let (d, l) = expr[i];
        if l > 9 {
            // split
            let (_,r) = expr[i];
            *expr.get_mut(i).unwrap() = (d+1, l/2);
            expr.insert(i+1, (d+1, (r+1)/2));
            reduce_expr(expr, i) // restart
        }
    }
}

fn add_expr(left: &mut Expr, right: &Expr) {
    left.extend(right);
    left.iter_mut().for_each(|(d,_)| *d += 1);
}

fn magnitude(expr: &Expr) -> u32 {
    let mut expr = expr.clone();
    let mut depth = expr.iter().fold(0, |acc, (d, _)| cmp::max(acc, *d));
    while depth > 0 {
        for i in 0..expr.len()-1 {
            if i >= expr.len()-1 {
                break
            }
            let ((dl, lv), (dr, rv)) = (expr[i], expr[i+1]);
            if dl == dr {
                expr[i] = (depth-1, 3 * lv + 2 * rv);
                expr.remove(i+1);
            }
        }
        depth -= 1;
    }
    expr[0].1
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let expressions: Vec<Expr> = input.lines().map(parse_expr).collect();
        let mut expr = expressions[0].clone();
        for e in expressions.iter().skip(1) {
            add_expr(&mut expr, e);
            reduce_expr(&mut expr, 0);
        }

        let answer = magnitude(&expr);
        
        format!("{}", answer)
    }

    fn part2(&self, input: &str) -> String {
        let expressions: Vec<Expr> = input.lines().map(parse_expr).collect();
        let mut max = u32::MIN;
        for l in 0..expressions.len() {
            for r in 0..expressions.len() {
                if l == r {
                    continue;
                }
                let mut lexpr = expressions[l].clone();
                let rexpr = expressions[r].clone();
                add_expr(&mut lexpr, &rexpr);
                // println!("{:?}", lexpr);
                reduce_expr(&mut lexpr, 0);
                max = cmp::max(max, magnitude(&lexpr));
            }
        }

        format!("{}", max)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_part1_reduce() {
        let mut expr = parse_expr("[[[[[4,3],4],4],[7,[[8,4],9]]],[1,1]]");
        reduce_expr(&mut expr, 0);
        assert_eq!(expr, [(4, 0), (4, 7), (3, 4), (4, 7), (4, 8), (4, 6), (4, 0), (2, 8), (2, 1)]);
    }
}

