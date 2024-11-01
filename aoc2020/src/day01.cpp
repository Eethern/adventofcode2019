#include <algorithm>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <optional>
#include <ostream>
#include <vector>
#include "problem.h"

#include <gtest/gtest.h>

class Day01 : public Problem {
   public:
    Day01(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<uint32_t> numbers{parse_input(this->input_)};
        for (uint32_t const& first : numbers) {
            for (uint32_t const& second : numbers) {
                if ((first + second) == 2020) {
                    return {true, first * second};
                }
            }
        }
        return {false, NULL};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<uint32_t> numbers{parse_input(this->input_)};
        std::sort(numbers.begin(), numbers.end());

        for (uint32_t const x : numbers) {
            if (x > 2020)
                break;

            for (uint32_t const y : numbers) {
                if (x + y > 2020)
                    break;

                for (uint32_t const z : numbers) {
                    if (x + y + z > 2020)
                        break;

                    if (x + y + z == 2020)
                        return {true, x * y * z};
                }
            }
        }

        return {false, NULL};
    }

   private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        std::vector<std::string> lines;
        this->read_file(file_name, lines);

        std::vector<std::uint32_t> output{};
        for (const std::string& line : lines) {
            output.push_back(static_cast<uint32_t>(stoi(line)));
        }

        return output;
    }
};

class Day01Test : public ::testing::Test {
   protected:
    Day01 problem_{"examples/01.txt"};
};

TEST_F(Day01Test, Example) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    if (result.first) {
        EXPECT_EQ(result.second, 514579U);
    }
}
