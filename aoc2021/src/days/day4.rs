use crate::problem::Problem;
use std::collections::HashMap;

pub struct DayFour {}

struct Bingo {
    num_map: HashMap<u32, Vec<(usize, usize, usize)>>,
    numbers: Vec<u32>,
    boards: Vec<Board>,
    finished_boards: Vec<bool>,
}

#[derive(Clone)]
struct Board {
    score: u32,
    raw_board: Vec<Vec<u32>>,
    row_counts: [u32; 5],
    col_counts: [u32; 5],
}

impl Bingo {
    fn parse_input(input: &str) -> Self {
        let (nums, boards) = input.split_once("\n\n").unwrap();
        let numbers = nums.split(',').map(|s| s.parse().unwrap()).collect();
        let boards: Vec<Board> = boards.split("\n\n").map(Board::parse).collect();
        let mut finished_boards = Vec::new();
        let mut num_map = HashMap::new();

        for (board_id, board) in boards.iter().enumerate() {
            for (row_i, row) in board.raw_board.iter().enumerate() {
                for (col_i, val) in row.iter().enumerate() {
                    num_map
                        .entry(*val)
                        .or_insert(Vec::new())
                        .push((board_id, row_i, col_i));
                }
            }
            finished_boards.push(false)
        }

        Bingo {
            num_map,
            numbers,
            boards,
            finished_boards,
        }
    }

    fn run(mut self) -> (Option<Board>, u32) {
        for num in self.numbers {
            for (board_id, row_i, col_i) in self.num_map[&num].iter() {
                let mut board = self.boards[*board_id].clone();
                board.row_counts[*row_i] -= 1;
                board.col_counts[*col_i] -= 1;
                board.score -= num;

                if board.row_counts[*row_i] == 0 || board.col_counts[*col_i] == 0 {
                    self.finished_boards[*board_id] = true;

                    return (Some(board), num);
                }

                self.boards[*board_id] = board;
            }
        }
        (None, 0)
    }

    fn find_loser(mut self) -> (Option<Board>, u32) {
        let mut num_left = self.boards.len();

        for num in self.numbers {
            for (board_id, row_i, col_i) in self.num_map[&num].iter() {
                if !self.finished_boards[*board_id] {
                    let mut board = self.boards[*board_id].clone();
                    board.row_counts[*row_i] -= 1;
                    board.col_counts[*col_i] -= 1;
                    board.score -= num;

                    if board.row_counts[*row_i] == 0 || board.col_counts[*col_i] == 0 {
                        num_left -= 1;
                        self.finished_boards[*board_id] = true;
                    }


                    if num_left == 0 {
                        return (Some(board), num)
                    }

                    self.boards[*board_id] = board;
                }

            }
        }
        (None, 0)
    }
}

impl Board {
    fn parse(input: &str) -> Board {
        let row_counts: [u32; 5] = [5; 5];
        let col_counts: [u32; 5] = [5; 5];
        let mut raw_board = Vec::new();
        let mut score: u32 = 0;

        for line in input.lines() {
            let nums: Vec<u32> = line
                .split_ascii_whitespace()
                .map(|n| n.parse().unwrap())
                .collect::<Vec<u32>>();

            score = nums.iter().fold(score, |acc, val| acc + val);
            raw_board.push(nums.clone());
        }

        Board {
            score,
            raw_board,
            row_counts,
            col_counts,
        }
    }
}

impl Problem for DayFour {
    fn part1(&self, input: &str) -> String {
        let bingo = Bingo::parse_input(input);
        let (board, num) = bingo.run();
        let solution = match board {
            Some(board) => board.score * num,
            None => 0,
        };

        format!("{}", solution)
    }

    fn part2(&self, input: &str) -> String {
        let bingo = Bingo::parse_input(input);
        let (board, num) = bingo.find_loser();
        let solution = match board {
            Some(board) => board.score * num,
            None => 0,
        };

        format!("{}", solution)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
