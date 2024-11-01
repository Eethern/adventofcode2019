#include <gtest/gtest.h>
#include <string>
#include "problem.h"

std::uint64_t find_invalid_number(std::vector<uint64_t> const& numbers,
                                  std::uint64_t buffer_size) {
    std::uint64_t pc = buffer_size;
    for (pc = buffer_size; pc < numbers.size(); ++pc) {
        bool found_match = false;
        for (std::uint64_t i = 0U; i < buffer_size; ++i) {
            for (std::uint64_t j = i + 1; j < buffer_size; ++j) {
                if (numbers.at(pc - i - 1) + numbers.at(pc - j - 1) ==
                    numbers.at(pc)) {
                    found_match = true;
                    break;
                }
            }
            if (found_match)
                break;
        }
        if (!found_match) {
            return numbers.at(pc);
        }
    }
    return 0;
}

std::uint64_t find_range(std::vector<uint64_t> const& numbers,
                         std::uint64_t invalid_number) {
    for (std::uint64_t i = 0U; i < numbers.size(); ++i) {
        std::uint64_t sum = numbers.at(i);
        std::uint64_t smallest = numbers.at(i);
        std::uint64_t largest = numbers.at(i);
        for (std::uint64_t j = i + 1; j < numbers.size(); ++j) {
            sum += numbers.at(j);
            smallest = std::min(numbers.at(j), smallest);
            largest = std::max(numbers.at(j), largest);

            if (sum == invalid_number)
                return smallest + largest;
            if (sum > invalid_number)
                break;
        }
    }

    return 0;
}

class Day09 : public Problem {
   public:
    Day09(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<uint64_t> numbers = parse_input(input_);
        std::uint64_t solution = find_invalid_number(numbers, 25U);
        return {true, solution};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<uint64_t> numbers = parse_input(input_);
        std::uint64_t invalid_number = find_invalid_number(numbers, 25U);
        std::uint64_t solution = find_range(numbers, invalid_number);

        return {true, solution};
    }

   private:
    std::vector<uint64_t> parse_input(std::string const& file_name) {
        std::vector<std::string> lines;
        read_file(file_name, lines);
        std::vector<uint64_t> numbers = {};
        for (auto& line : lines) {
            numbers.push_back(std::stoull(line));
        }
        return numbers;
    }
};

class Day09Test : public ::testing::Test {
   protected:
    Day09 problem_{"examples/09.txt"};
};

TEST_F(Day09Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day09Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
