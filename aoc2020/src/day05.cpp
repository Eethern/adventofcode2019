#include <gtest/gtest.h>
#include <array>
#include "problem.h"
class Day05 : public Problem {
   public:
    Day05(const std::string& input) : Problem(input) {}
    std::pair<std::size_t, std::size_t> decode_boarding_pass(
        std::string const& pass) {
        size_t row{0U}, col{0U};
        size_t idx{pass.length()};
        for (char c : pass) {
            switch (c) {
                case 'B':
                    row += ((1 << (idx - 3 - 1)));
                    break;
                case 'R':
                    col += ((1 << (idx - 1)));
                    break;
                default:
                    break;
            }

            idx--;
        }
        return {row, col};
    }
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        size_t largest_id{0U};
        for (std::string const& line : lines) {
            std::pair<std::size_t, std::size_t> pos{decode_boarding_pass(line)};
            largest_id = std::max(largest_id, pos.first * 8U + pos.second);
        }
        return {true, static_cast<std::uint64_t>(largest_id)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        std::vector<char> seats((1 << 7) * (1 << 3), 0);

        for (std::string const& line : lines) {
            std::pair<std::size_t, std::size_t> pos{decode_boarding_pass(line)};
            seats.at(pos.first * (1 << 3) + pos.second) = 1;
        }

        for (size_t i{1U}; i < seats.size() - 1; ++i) {
            if (seats.at(i - 1) == 1 && seats.at(i) == 0 &&
                seats.at(i + 1) == 1) {
                return {true, static_cast<std::uint64_t>(i)};
            }
        }

        return {false, NULL};
    }
};

class Day05Test : public ::testing::Test {
   protected:
    Day05 problem_{"examples/05.txt"};
};

TEST_F(Day05Test, part1) {
    std::string casea{"BFFFBBFRRR"};
    // row = 0 + 2 + 4 + 0 + 0 + 0 + 64 = 70
    // col = 1 + 2 + 4 = 7
    std::pair<size_t, size_t> pos{problem_.decode_boarding_pass(casea)};

    ASSERT_EQ(pos.first, 70);
    ASSERT_EQ(pos.second, 7);
}
