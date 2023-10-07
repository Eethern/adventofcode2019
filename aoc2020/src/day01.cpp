#include <iostream>
#include <algorithm>
#include <fstream>
#include <ostream>
#include <vector>
#include <optional>
#include <cstdint>
#include "problem.h"

#include <gtest/gtest.h>

class Day01 : public Problem
{
public:
    std::pair<bool, std::uint32_t> part1(std::string const& file_name) override
    {
        std::vector<uint32_t> numbers{parse_input(file_name)};
        for (uint32_t const& first : numbers) {
            for (uint32_t const& second : numbers) {
                if ((first + second) == 2020) {
                    return {true, first * second};
                }
            }
        }
        return {false, NULL};
    }

    std::pair<bool, std::uint32_t> part2(std::string const& file_name) override
    {
        std::vector<uint32_t> numbers{parse_input(file_name)};
        std::sort(numbers.begin(), numbers.end());

        for (uint32_t const x : numbers) {
            if (x > 2020) break;

            for (uint32_t const y : numbers) {
                if (x + y > 2020) break;

                for (uint32_t const z : numbers) {
                    if (x + y + z > 2020) break;

                    if (x + y + z == 2020)
                        return {true, x*y*z};
                }
            }
        }

        return {false, NULL};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name)
    {
        std::vector<std::string> lines;
        this->read_file(file_name, lines);

        std::vector<std::uint32_t> output{};
        for (const std::string& line : lines) {
            output.push_back(static_cast<uint32_t>(stoi(line)));
        }

        return output;
    }
};

class Day01Test : public ::testing::Test
{
protected:
    Day01 problem_{};
};

TEST_F(Day01Test, Example)
{
    std::pair<bool, std::uint32_t> result{problem_.part1("examples/01.txt")};
    if (result.first) {
        EXPECT_EQ(result.second, 514579U);
    }
}
