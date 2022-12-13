use crate::problem::Problem;

pub struct Solution {}

#[derive(Debug)]
enum List {
    List(Vec<List>),
    Item(u8),
}

impl Ord for List {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        match (self, other) {
            (List::Item(n1), List::Item(n2)) => n1.cmp(n2);
            (List(l1), List(l2)) => {
                todo!()
                

            },
            (List(l1), List::Item(n2)) => l1.cmp(List::List(vec![List::Item(n2)])),
            (List(n1), List::Item(l2)) => List::List[vec![List::Item(n1)]].cmp(l2),
        }

    }
}

fn parse_items(bytes: &[u8], pos: &mut usize) -> List {
    let mut out = vec![];
    while bytes[*pos] != b']' {
        let c = bytes[*pos];
        match c {
            b'[' => {
                *pos += 1;
                out.push(parse_items(bytes, pos));
            },
            b']' => {
                *pos += 1;

            }
            b',' => {
                *pos += 1;
            }
            c => {
                out.push(parse_number(bytes, pos));
            }
        };
    }

    List::List(out)

}

fn parse_number(bytes: &[u8], pos: &mut usize) -> List {
    let mut number = 0;
    while bytes[*pos].is_ascii_digit() {
        number = number * 10 + bytes[*pos] - b'0';
        *pos += 1;
    }

    List::Item(number)
}

fn parse_line(line: &str) -> List {
    // let mut out: = vec![];

    let bytes = line.as_bytes();

    let mut pos = 0;
    if bytes[pos] == b'[' {
        pos += 1;
        let items = parse_items(bytes, &mut pos);
        dbg!(&items);
    }

    List::Item(8)
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        _input.split("\n\n").map(|pair| {
            let (left, right) = pair.split_once('\n').unwrap();
            let left = parse_line(left);
            let righ = parse_line(right);
        });
        // Some(format!("{}", "undefined"))
        None
    }

    fn part2(&self, _input: &str) -> Option<String> {
        // Some(format!("{}", "undefined"))
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_day13_parse() {
        let input = "[1,[2,[3,[4,[5,6,7]]]],8,9]";

        parse_line(input);
        assert!(false);

        
    }
}
