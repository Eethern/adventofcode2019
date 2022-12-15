use std::cmp::Ordering;

use crate::problem::Problem;

pub struct Solution {}

#[derive(Debug, Eq, PartialEq, Clone)]
enum Packet {
    List(Vec<Packet>),
    Item(u8),
}

impl PartialOrd for Packet {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        use Packet::*;
        match (self, other) {
            (Item(ref a), Item(ref b)) => a.partial_cmp(b),
            (List(ref lists), List(ref other_lists)) => lists
                .iter()
                .zip(other_lists)
                .fold(None, |ord, (i1, i2)| {
                    ord.or(match i1.cmp(i2) {
                        Ordering::Less => Some(Ordering::Less),
                        Ordering::Equal => None,
                        Ordering::Greater => Some(Ordering::Greater),
                    })
                })
                .or_else(|| lists.len().partial_cmp(&other_lists.len())),
            (List(_), Item(_)) => self.partial_cmp(&List(vec![other.clone()])),
            (Item(_), List(_)) => List(vec![self.clone()]).partial_cmp(other),
        }
    }
}

impl Ord for Packet {
    fn cmp(&self, other: &Self) -> Ordering {
        self.partial_cmp(other).unwrap()
    }
}
fn parse_list_members(line: &[u8], pos: &mut usize) -> Packet {
    let mut result = vec![];
    while line[*pos] != b']' {
        if line[*pos] == b'[' {
            result.push(parse_bytes(line, pos));
            if line[*pos] == b',' {
                *pos += 1;
                continue;
            }
        } else if line[*pos].is_ascii_digit() {
            result.push(parse_number(line, pos));
            if line[*pos] == b',' {
                *pos += 1;
                continue;
            }
        }
    }
    Packet::List(result)
}

fn parse_number(line: &[u8], pos: &mut usize) -> Packet {
    let mut result = 0;
    while line[*pos].is_ascii_digit() {
        result = result * 10 + (line[*pos] - b'0');
        *pos += 1;
    }
    Packet::Item(result)
}

fn parse_bytes(line: &[u8], pos: &mut usize) -> Packet {
    if line[*pos] == b'[' {
        *pos += 1;
        let result = parse_list_members(line, pos);
        *pos += 1;
        result
    } else if line[*pos].is_ascii_digit() {
        parse_number(line, pos)
    } else {
        panic!("Unknown data {}", line[*pos]);
    }
}

fn parse_line(line: &str) -> Packet {
    let line = line.as_bytes();
    parse_bytes(line, &mut 0)
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let answer: usize = _input
            .split("\n\n")
            .enumerate()
            .map(|(ind, pair)| {
                let (left, right) = pair.split_once('\n').unwrap();
                let left_list = parse_line(left);
                let right_list = parse_line(right);
                (ind, left_list.cmp(&right_list))
            })
            .filter(|(_, o)| *o == Ordering::Less || *o == Ordering::Equal)
            .map(|(ind, _)| ind + 1)
            .sum::<usize>();

        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let div1 = parse_line("[[2]]");
        let div2 = parse_line("[[6]]");
        let new_input = _input.replace("\n\n", "\n");
        let packets = new_input.lines().map(|l| parse_line(l)).collect::<Vec<Packet>>();

        let p1 = packets.iter().filter(|&p| p < &div1).count() + 1;
        let p2 = packets.iter().filter(|&p| p < &div2).count() + 2;

        Some((p1 * p2).to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn check_ordering(input: &str, expected_ordering: Ordering) {
        let (left, right) = input.split_once("\n").unwrap();
        let (left, right) = (parse_line(left), parse_line(right));
        let ordering = left.cmp(&right);
        assert_eq!(ordering, expected_ordering);
    }

    #[test]
    fn test_day13_ordering() {
        check_ordering("[1,1,3,1,1]\n[1,1,5,1,1]", Ordering::Less);
        check_ordering("[[1],[2,3,4]]\n[[1],4]", Ordering::Less);
        check_ordering("[9]\n[[8,7,6]]", Ordering::Greater);
        check_ordering("[[4,4],4,4]\n[[4,4],4,4,4]", Ordering::Less);
        check_ordering("[7,7,7,7]\n[7,7,7]", Ordering::Greater);
        check_ordering("[]\n[3]", Ordering::Less);
        check_ordering("[[[]]]\n[[]]", Ordering::Greater);
        check_ordering(
            "[1,[2,[3,[4,[5,6,7]]]],8,9]\n[1,[2,[3,[4,[5,6,0]]]],8,9]",
            Ordering::Greater,
        );
        check_ordering("[[1,1],2]\n[[1,1],1]", Ordering::Greater);
        check_ordering("[[0,0,0],4]\n[[0,0,0],0]", Ordering::Greater);
        check_ordering("[]\n[]", Ordering::Equal);
        check_ordering("[[],4]\n[[],3]", Ordering::Greater);
        check_ordering("[4,[],4]\n[4,[],3]", Ordering::Greater);
        check_ordering("[1]\n[[1,2,3]]", Ordering::Less);
    }

    #[test]
    fn test_day13a_full() {
        let input = vec![
            "[1,1,3,1,1]\n[1,1,5,1,1]",
            "[[1],[2,3,4]]\n[[1],4]",
            "[9]\n[[8,7,6]]",
            "[[4,4],4,4]\n[[4,4],4,4,4]",
            "[7,7,7,7]\n[7,7,7]",
            "[]\n[3]",
            "[[[]]]\n[[]]",
            "[1,[2,[3,[4,[5,6,7]]]],8,9]\n[1,[2,[3,[4,[5,6,0]]]],8,9]",
        ]
        .join("\n\n");

        let solution = Solution {};
        let answer = solution.part1(&input).unwrap();
        assert_eq!(answer, "13");
    }

    #[test]
    fn test_day13b() {
        let input = vec![
            "[1,1,3,1,1]\n[1,1,5,1,1]",
            "[[1],[2,3,4]]\n[[1],4]",
            "[9]\n[[8,7,6]]",
            "[[4,4],4,4]\n[[4,4],4,4,4]",
            "[7,7,7,7]\n[7,7,7]",
            "[]\n[3]",
            "[[[]]]\n[[]]",
            "[1,[2,[3,[4,[5,6,7]]]],8,9]\n[1,[2,[3,[4,[5,6,0]]]],8,9]",
        ]
        .join("\n\n");

        let solution = Solution {};
        let answer = solution.part2(&input).unwrap();
        assert_eq!(answer, "140");
    }
}
