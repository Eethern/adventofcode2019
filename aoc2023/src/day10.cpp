#include <gtest/gtest.h>
#include <utility>

#include "problem.h"

struct XY {
    int32_t x;
    int32_t y;
};

enum Dir {
    North = 0,
    South,
    East,
    West,
    Unknown,
};

const std::map<std::pair<char, Dir>, Dir> TILEDIR_TO_NEW_DIR = {
    {{'|', North}, North},
    {{'|', South}, South},
    {{'-', West}, West},
    {{'-', East}, East},   {{'L', West}, North},  {{'L', South}, East},
    {{'J', East}, North},  {{'J', South}, West},  {{'7', North}, West},
    {{'7', East}, South},  {{'F', North}, East},  {{'F', West}, South},
};

constexpr std::pair<XY, Dir> NEIGHBORS[4] = {
    {{0, 1}, South},
    {{1, 0}, East},
    {{0, -1}, North},
    {{-1, 0}, West},
};

const std::map<Dir, XY> DIR_TO_OFFSETS = {
    {North, {0, -1}}, {South, {0, 1}}, {East, {1, 0}}, {West, {-1, 0}}};

struct Explorer {
    XY position;
    Dir dir;
    uint32_t steps_taken;
};

XY find_start(std::vector<std::string> const& lines) {
    int32_t row{0};
    int32_t col{0};
    for (std::string const& line : lines) {
        col = 0;

        for (char c : line) {
            if (c == 'S') {
                return {col, row};
            }
            col++;
        }
        row++;
    }
    return {col, row};
}

class Day10 : public Problem {
public:
    Day10(const std::string& input) : Problem(input) {
    }
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines{};
        read_file(input_, lines);

        int32_t max_x = static_cast<int32_t>(lines[0].size());
        int32_t max_y = static_cast<int32_t>(lines.size());

        XY start{find_start(lines)};

        std::vector<Explorer> explorers{};
        for (std::pair<XY, Dir> const& offset_dir : NEIGHBORS) {
            Explorer exp{};
            exp.position = {start.x + offset_dir.first.x,
                            start.y + offset_dir.first.y};
            exp.dir = offset_dir.second;
            exp.steps_taken = 1U;
            explorers.push_back(exp);
        }

        uint32_t steps{0U};
        while (steps == 0U) {
            for (Explorer& exp : explorers) {
                XY& pos{exp.position};

                if (pos.x > max_x || pos.x < 0 || pos.y > max_y ||
                    pos.y < 0) {
                    continue;
                }
                char c{lines[pos.y][pos.x]};

                if (c == '.') {
                    continue;
                }

                if (c == 'S') {
                    steps = exp.steps_taken;
                    break;
                }


                std::pair<char, Dir> key{std::make_pair(c, exp.dir)};
                if (TILEDIR_TO_NEW_DIR.count(key) == 0U) {
                    continue;
                }
                Dir new_dir{TILEDIR_TO_NEW_DIR.at(key)};

                XY const& offset{DIR_TO_OFFSETS.at(new_dir)};
                pos.x += offset.x;
                pos.y += offset.y;
                exp.dir = new_dir;
                exp.steps_taken += 1;
            }
        }

        return {true, (steps / 2U)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        return {false, NULL};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day10Test : public ::testing::Test {
protected:
    Day10 problem_{"examples/10.txt"};
};

TEST_F(Day10Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day10Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
