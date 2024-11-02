#include <gtest/gtest.h>
#include "problem.h"
#include "string_view.h"

typedef enum { NoSeat = 0, UnOccupied, Occupied } CellState;

class Automata {
   public:
    Automata(std::vector<std::string> const& lines) {
        width_ = lines.at(0).size();
        height_ = lines.size();
        cells_ = std::vector<CellState>();
        for (auto& line : lines) {
            for (char c : line) {
                CellState cell_state = NoSeat;
                switch (c) {
                    case 'L':
                        cell_state = CellState::UnOccupied;
                        break;
                    case '#':
                        cell_state = CellState::Occupied;
                        break;
                    default:
                        cell_state = CellState::NoSeat;
                        break;
                }
                cells_.push_back(cell_state);
            }
        }
    }

    CellState get_cell_state(size_t x, size_t y) const {
        size_t idx = y * width_ + x;
        assert(idx < cells_.size());
        return cells_.at(idx);
    }

    friend std::ostream& operator<<(std::ostream& os, const Automata& obj) {
        for (size_t y = 0U; y < obj.height_; ++y) {
            for (size_t x = 0U; x < obj.width_; ++x) {
                switch (obj.get_cell_state(x, y)) {
                    case CellState::NoSeat:
                        os << '.';
                        break;
                    case CellState::UnOccupied:
                        os << 'L';
                        break;
                    case CellState::Occupied:
                        os << '#';
                        break;
                }
            }
            os << std::endl;
        }
        return os;
    }

    bool tick1() {
        // Copy cells buffer
        std::vector<CellState> cells_copy = cells_;
        for (size_t y = 0U; y < height_; ++y) {
            for (size_t x = 0U; x < width_; ++x) {
                CellState cell_state = get_cell_state(x, y);

                size_t num_occupied_neighbors = 0U;
                for (std::int32_t dy = -1; dy <= 1; ++dy) {
                    std::int32_t ny = static_cast<std::int32_t>(y) + dy;
                    if (ny < 0 || ny >= static_cast<std::int32_t>(height_)) {
                        continue;
                    }
                    for (std::int32_t dx = -1; dx <= 1; ++dx) {

                        if (dx == 0 && dy == 0)
                            continue;

                        std::int32_t nx = static_cast<std::int32_t>(x) + dx;
                        if (nx < 0 || nx >= static_cast<std::int32_t>(width_)) {
                            continue;
                        }
                        if (get_cell_state(nx, ny) == CellState::Occupied) {
                            num_occupied_neighbors++;
                        }
                    }
                }

                if (cell_state == CellState::UnOccupied &&
                    num_occupied_neighbors == 0) {
                    cell_state = CellState::Occupied;
                } else if (cell_state == CellState::Occupied &&
                           num_occupied_neighbors >= 4U) {
                    cell_state = CellState::UnOccupied;
                }

                cells_copy.at(y * width_ + x) = cell_state;
            }
        }
        bool is_stable = false;
        if (cells_ == cells_copy) {
            is_stable = true;
        }
        cells_ = cells_copy;

        return is_stable;
    }

    bool tick2() {
        // Copy cells buffer
        std::vector<CellState> cells_copy = cells_;
        for (size_t y = 0U; y < height_; ++y) {
            for (size_t x = 0U; x < width_; ++x) {
                CellState cell_state = get_cell_state(x, y);

                size_t num_occupied_neighbors = 0U;
                for (std::int32_t dy = -1; dy <= 1; ++dy) {
                    for (std::int32_t dx = -1; dx <= 1; ++dx) {
                        if (dx == 0 && dy == 0)
                            continue;

                        int32_t nx = static_cast<std::int32_t>(x) + dx;
                        int32_t ny = static_cast<std::int32_t>(y) + dy;

                        while (nx >= 0 && nx < static_cast<std::int32_t>(width_) && ny >= 0 &&
                               ny < static_cast<std::int32_t>(height_)) {
                            CellState cs =
                                get_cell_state(static_cast<std::uint32_t>(nx),
                                               static_cast<std::uint32_t>(ny));
                            if (cs == CellState::Occupied) {
                                num_occupied_neighbors++;
                                break;
                            } else if (cs == CellState::UnOccupied) {
                                break;
                            }

                            nx += dx;
                            ny += dy;
                        }
                    }
                }

                if (cell_state == CellState::UnOccupied &&
                    num_occupied_neighbors == 0) {
                    cell_state = CellState::Occupied;
                } else if (cell_state == CellState::Occupied &&
                           num_occupied_neighbors >= 5U) {
                    cell_state = CellState::UnOccupied;
                }

                cells_copy.at(y * width_ + x) = cell_state;
            }
        }
        bool is_stable = false;
        if (cells_ == cells_copy) {
            is_stable = true;
        }
        cells_ = cells_copy;

        return is_stable;
    }

    std::vector<CellState> cells_;
    std::size_t height_;
    std::size_t width_;
};

class Day11 : public Problem {
   public:
    Day11(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        Automata automata(lines);
        // automata.tick1();
        // std::cout << automata << std::endl;
        while (!automata.tick1()) {}

        size_t num_occupied = 0U;
        for (CellState cell_state : automata.cells_) {
            if (cell_state == CellState::Occupied) {
                num_occupied++;
            }
        }

        return {true, num_occupied};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        Automata automata(lines);
        while (!automata.tick2()) {}

        size_t num_occupied = 0U;
        for (CellState cell_state : automata.cells_) {
            if (cell_state == CellState::Occupied) {
                num_occupied++;
            }
        }

        return {true, num_occupied};
    }
};

class Day11Test : public ::testing::Test {
   protected:
    Day11 problem_{"examples/11.txt"};
};

TEST_F(Day11Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day11Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
