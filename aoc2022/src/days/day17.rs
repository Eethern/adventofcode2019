use std::collections::HashSet;

use crate::problem::Problem;

pub struct Solution {}

const WIDTH: usize = 7;

struct Game {
    board: Board,
    block_order: Vec<BlockType>,
    inputs: Vec<Dir>,
    block_count: usize,
    tick: usize,
}

impl Game {
    fn new(width: usize, block_order: Vec<BlockType>, inputs: Vec<Dir>) -> Self {
        Self {
            board: Board::new(width),
            block_order,
            inputs,
            block_count: 0,
            tick: 0,
        }
    }

    fn run(&mut self, n_blocks: usize) {
        for i in 0..n_blocks {
            if i % 100 == 0 {
                println!("Dropping block {}", i);
            }
            let next_block = self.block_order[self.block_count % self.block_order.len()];
            self.drop_block(next_block);
        }
    }

    fn drop_block(&mut self, block_type: BlockType) {
        let mut block = Block::new(block_type);
        let height = block.get_height() as i32;
        block.points.iter_mut().for_each(|p| {
            p.x += 2;
            p.y += self.board.height as i32 + 3
        });
        loop {
            let dir = self.inputs[self.tick % self.inputs.len()];
            self.tick += 1;

            block.translate(dir);
            if self.board.collides(&block) {
                block.translate(dir.inverse());
            }


            block.translate(Dir::Down);

            if self.board.collides(&block) {
                // lock the block
                block.translate(Dir::Up);
                self.board.lock_block(&block);

                self.board.height = self
                    .board
                    .height
                    .max((block.points.iter().map(|p| p.y).max().unwrap_or(0)) as usize + 1);

                self.block_count += 1;
                break;
            }
        }
    }
}

struct Board {
    width: usize,
    height: usize,
    data: HashSet<Point>,
}

impl Board {
    fn new(width: usize) -> Self {
        Self {
            width,
            height: 0,
            data: HashSet::new(),
        }
    }

    fn is_filled(&self, point: &Point) -> bool {
        self.data.contains(point)
    }

    fn collides(&self, block: &Block) -> bool {
        block
            .points
            .iter()
            .any(|p| self.data.contains(p) || p.y < 0 || p.x < 0 || p.x >= self.width as i32)
    }

    fn lock_block(&mut self, block: &Block) {
        block.points.iter().for_each(|p| {
            self.data.insert(p.clone());
        })
    }
}

#[derive(Debug, Copy, Clone)]
enum Dir {
    Left,
    Right,
    Down,
    Up,
}

impl Dir {
    fn as_vector(&self) -> Point {
        match self {
            Dir::Left => Point { x: -1, y: 0 },
            Dir::Right => Point { x: 1, y: 0 },
            Dir::Down => Point { x: 0, y: -1 },
            Dir::Up => Point { x: 0, y: 1 },
        }
    }

    fn inverse(&self) -> Dir {
        match self {
            Dir::Left => Dir::Right,
            Dir::Right => Dir::Left,
            Dir::Down => Dir::Up,
            Dir::Up => Dir::Down,
        }
    }
}

#[derive(Debug, Clone, Copy)]
enum BlockType {
    Minus,
    Plus,
    Corner,
    Wall,
    Square,
}

#[derive(Debug, Eq, PartialEq, Hash, Copy, Clone)]
struct Point {
    x: i32,
    y: i32,
}

#[derive(Debug)]
struct Block {
    block_type: BlockType,
    points: Vec<Point>,
}

fn get_cells(block_type: BlockType) -> Vec<Point> {
    let coords = match block_type {
        BlockType::Minus => vec![(0, 0), (1, 0), (2, 0), (3, 0)],
        BlockType::Plus => vec![(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)],
        BlockType::Corner => vec![(0, 0), (1,0), (2,0), (2,1), (2,2)],
        BlockType::Wall => vec![(0, 0), (0, 1), (0, 2), (0, 3)],
        BlockType::Square => vec![(0, 0), (0, 1), (1, 0), (1, 1)],
    };
    coords.iter().map(|(x, y)| Point { x: *x, y: *y }).collect()
}

impl Block {
    fn new(block_type: BlockType) -> Block {
        Block {
            block_type,
            points: get_cells(block_type),
        }
    }

    fn translate(&mut self, dir: Dir) {
        let vec = dir.as_vector();
        self.points = self
            .points
            .iter()
            .map(|p| Point {
                x: p.x + vec.x,
                y: p.y + vec.y,
            })
            .collect()
    }

    fn collides_with(&self, block: &Block) -> bool {
        self.points.iter().any(|p| block.points.contains(p))
    }

    fn get_height(&self) -> usize {
        match self.block_type {
            BlockType::Minus => 1,
            BlockType::Plus => 3,
            BlockType::Corner => 3,
            BlockType::Wall => 4,
            BlockType::Square => 2,
        }
    }
}

fn parse_directions(input: &str) -> Vec<Dir> {
    input
        .chars()
        .map(|c| match c {
            '<' => Dir::Left,
            '>' => Dir::Right,
            _ => panic!("Could not parse direction {}", c),
        })
        .collect()
}

fn get_block_order() -> Vec<BlockType> {
    vec![
        BlockType::Minus,
        BlockType::Plus,
        BlockType::Corner,
        BlockType::Wall,
        BlockType::Square,
    ]
}

impl Problem for Solution {
    fn part1(&self, _input: &str) -> Option<String> {
        let ticks = 2022;
        let directions = parse_directions(_input);
        let block_order = get_block_order();
        let mut game = Game::new(WIDTH, block_order, directions);
        game.run(ticks);

        let answer = game.board.height;
        Some(answer.to_string())
    }

    fn part2(&self, _input: &str) -> Option<String> {
        let ticks = 1_000_000_000_000;
        let directions = parse_directions(_input);
        let block_order = get_block_order();
        let mut game = Game::new(WIDTH, block_order, directions);
        game.run(ticks);

        let answer = game.board.height;
        Some(answer.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT: &str = ">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>";

    #[test]
    fn test_day17a() {
        let ticks = 2022;
        let directions = parse_directions(INPUT);
        let block_order = get_block_order();
        let mut game = Game::new(WIDTH, block_order, directions);
        game.run(ticks);

        let answer = game.board.height;
        assert_eq!(answer, 3068);
    }
}
