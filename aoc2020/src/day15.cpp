#include <gtest/gtest.h>
#include "problem.h"
#include "string_view.h"
class Day15 : public Problem {
   public:
    Day15(const std::string& input) : Problem(input) {}
    std::uint64_t solve(std::uint64_t iterations) {
        std::string numbers = read_file_raw(input_);
        StringView sv{numbers};

        std::map<std::uint64_t, std::vector<std::uint64_t>> number_to_timestamps{};
        std::uint64_t numbers_spoken = 0U;
        std::uint64_t current_number = 0U;
        while (numbers_spoken < iterations) {
            if (sv.size() > 0U) {
                current_number = sv.chop_by_delim(',').chop_number<std::uint64_t>();
                numbers_spoken++;
                number_to_timestamps[current_number] = {numbers_spoken};
                continue;
            }

            if (number_to_timestamps.count(current_number) > 0) {
                if (number_to_timestamps[current_number].size() > 1) {
                    std::vector<std::uint64_t> const& v = number_to_timestamps[current_number];
                    current_number = v[v.size()-1U] - v[v.size() - 2U];
                } else {
                    current_number = 0;
                }
                numbers_spoken++;
                number_to_timestamps[current_number].push_back(numbers_spoken);
            } else {
                number_to_timestamps[current_number] = {numbers_spoken};
                current_number = 0;
                numbers_spoken++;

            }
        }

        return current_number;
    }
    std::pair<bool, std::uint64_t> part1() override {
        return {true, solve(2020U)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        return {true, solve(30000000U)};
    }

   private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day15Test : public ::testing::Test {
   protected:
    Day15 problem_{"examples/15.txt"};
};

TEST_F(Day15Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day15Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
