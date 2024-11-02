#include <gtest/gtest.h>
#include <cstdint>
#include "problem.h"
class Day06 : public Problem {
   public:
    Day06(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        std::size_t answer{0U};
        std::uint32_t charmask{0U};
        std::size_t num_questions{0U};
        for (std::string line : lines) {
            if (line.size() == 0) {
                charmask = 0U;
                answer += num_questions;
                num_questions = 0U;
                continue;
            }
            for (char c : line) {
                std::uint32_t cmask = (1U << char_to_index(c));
                if ((charmask & cmask) == 0) {
                    num_questions += 1;
                    charmask |= cmask;
                }
            }
        }
        answer += num_questions;
        return {true, answer};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        std::size_t final_answer{0U};
        std::size_t person_idx{0U};
        std::vector<std::uint32_t> person_masks{};

        for (std::string line : lines) {
            if (line.size() == 0) {
                final_answer += compute_group_answer(person_masks);

                person_idx = 0U;
                person_masks.clear();
            } else {
                person_masks.push_back(0U);
                for (char c : line) {
                    person_masks[person_idx] |= (1 << char_to_index(c));
                }
                person_idx++;
            }
        }
        final_answer += compute_group_answer(person_masks);
        return {true, final_answer};
    }

   private:
    std::size_t compute_group_answer(
        std::vector<std::uint32_t> const& person_masks) {
        std::uint32_t group_mask = UINT32_MAX;
        for (std::uint32_t pmask : person_masks) {
            group_mask &= pmask;
        }

        std::size_t num_answers{0U};
        for (size_t i{0U}; i < 32; ++i) {
            size_t idx = (1U << i);
            if ((group_mask & idx) != 0U) {
                num_answers += 1U;
            }
        }

        return num_answers;
    }
    std::size_t char_to_index(char c) const {
        return static_cast<std::size_t>(c) - 97;
    }
};

class Day06Test : public ::testing::Test {
   protected:
    Day06 problem_{"examples/06.txt"};
};

TEST_F(Day06Test, part1) {}

TEST_F(Day06Test, part2) {}
