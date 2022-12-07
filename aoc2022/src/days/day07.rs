use crate::problem::Problem;

use std::cell::RefCell;
use std::fmt;
use std::rc::Rc;

pub struct Solution {}

enum NodeValue {
    Dir(String),
    File(u32),
}

struct Node {
    value: Option<NodeValue>,
    children: Vec<Rc<RefCell<Node>>>,
    parent: Option<Rc<RefCell<Node>>>,
}

impl fmt::Display for Node {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match &self.value {
            Some(v) => write!(f, "{}", v.to_string()),
            None => write!(
                f,
                "[{:?}]",
                self.children
                    .iter()
                    .map(|tn| tn.borrow().to_string())
                    .collect::<Vec<String>>()
                    .join(",")
            ),
        }
    }
}

impl fmt::Display for NodeValue {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            NodeValue::Dir(name) => write!(f, "dir({})", name),
            NodeValue::File(n) => write!(f, "file({})", n),
        }
    }
}

impl Node {
    fn new(value: NodeValue) -> Node {
        return Node {
            value: Some(value),
            children: vec![],
            parent: None,
        };
    }

    fn post_traverse(&self, dir_sizes: &mut Vec<u32>) -> u32 {
        match self.value.as_ref().unwrap() {
            NodeValue::Dir(_) => {
                let sum = self
                    .children
                    .iter()
                    .map(|c| c.borrow().post_traverse(dir_sizes))
                    .sum();

                dir_sizes.push(sum);
                sum
            }
            NodeValue::File(s) => *s,
        }
    }
}

fn parse_to_tree(input: &str) -> Rc<RefCell<Node>> {
    // Parse the input to a tree structure.
    let root = Rc::new(RefCell::new(Node::new(NodeValue::Dir("root".to_string()))));
    let mut path = vec![Rc::clone(&root)];
    path.push(Rc::clone(&root));
    input
        .lines()
        .for_each(|l| match l.split(" ").collect::<Vec<&str>>()[..] {
            ["$", "cd", ".."] => {
                // Up
                path.pop().unwrap();
            }
            ["$", "cd", name] => {
                // cd into dir
                let curr = path.last().unwrap();
                let child = Rc::new(RefCell::new(Node::new(NodeValue::Dir(name.to_string()))));
                curr.borrow_mut().children.push(Rc::clone(&child));
                {
                    let mut mut_child = child.borrow_mut();
                    mut_child.parent = Some(Rc::clone(&path.last().unwrap()));
                }
                path.push(Rc::clone(&child));
            }
            ["$", "ls"] => (), // continue
            ["dir", _] => (),
            [size, _] => {
                let curr = path.last().unwrap();
                let child = Rc::new(RefCell::new(Node::new(NodeValue::File(
                    size.parse::<u32>().unwrap(),
                ))));
                curr.borrow_mut().children.push(Rc::clone(&child));
                {
                    let mut mut_child = child.borrow_mut();
                    mut_child.parent = Some(Rc::clone(&curr));
                    mut_child.value = Some(NodeValue::File(size.parse().unwrap()));
                }
            }
            _ => (),
        });

    root
}

const MAX_SIZE: u32 = 100_000;
const MIN_REQUIRED: u32 = 30_000_000;
const MAX_SPACE: u32 = 70_000_000;

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let tree = parse_to_tree(_input);
        let mut sizes = vec![];
        tree.borrow().post_traverse(&mut sizes);
        let total = sizes.iter().filter(|&s| *s <= MAX_SIZE).sum::<u32>();

        Some(total.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let tree = parse_to_tree(_input);
        let mut sizes = vec![];
        tree.borrow().post_traverse(&mut sizes);

        let total = sizes.pop().unwrap();
        let answer = *sizes
            .iter()
            .filter(|&s| MAX_SPACE >= MIN_REQUIRED + total - s)
            .min()
            .unwrap();

        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = "$ cd /
$ ls
dir a
14848514 b.txt
8504156 c.dat
dir d
$ cd a
$ ls
dir e
29116 f
2557 g
62596 h.lst
$ cd e
$ ls
584 i
$ cd ..
$ cd ..
$ cd d
$ ls
4060174 j
8033020 d.log
5626152 d.ext
7214296 k
";

    #[test]
    fn test_day07a() {
        let tree = parse_to_tree(INPUT);
        let mut sizes = vec![];
        tree.borrow().post_traverse(&mut sizes);
        let total = sizes.iter().filter(|&s| *s <= MAX_SIZE).sum::<u32>();

        assert_eq!(total, 95437);
    }

    #[test]
    fn test_day07b() {
        let tree = parse_to_tree(INPUT);
        let mut sizes = vec![];
        tree.borrow().post_traverse(&mut sizes);

        let total = sizes.pop().unwrap();
        let answer = *sizes
            .iter()
            .filter(|&s| MAX_SPACE >= MIN_REQUIRED + total - s)
            .min()
            .unwrap();

        assert_eq!(answer, 24933642);
        // let total = sizes.iter().filter(|&s| *s <= MAX_SIZE).sum::<u32>();
    }
}
