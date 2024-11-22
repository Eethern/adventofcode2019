#include <gtest/gtest.h>
#include <bitset>
#include <cstring>
#include "problem.h"
#include "string_view.h"

enum class Op {
    Store,
    Mask,
};

typedef struct {
    Op op;
    std::uint64_t operand1;
    std::uint64_t operand2;
} Instr;

typedef struct {
    std::uint64_t set_mask;
    std::uint64_t reset_mask;
    std::vector<Instr> instructions;
    std::map<std::uint64_t, std::uint64_t> memory;
} Computer;

void print_computer(Computer const& computer) {
    std::cout << "set: " << std::bitset<64>(computer.set_mask) << std::endl;
    std::cout << "reset: " << std::bitset<64>(computer.reset_mask) << std::endl;
    std::cout << "size: " << computer.instructions.size() << std::endl;
    for (auto instr : computer.instructions) {
        std::cout << instr.operand1 << "->" << instr.operand2 << std::endl;
    }
}

class Day14 : public Problem {
   public:
    Day14(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<Instr> instructions = parse_input(input_);

        Computer computer = {0U, 0U, instructions, {}};

        for (auto& instr : computer.instructions) {
            if (instr.op == Op::Mask) {
                computer.set_mask = instr.operand1;
                computer.reset_mask = instr.operand2;
            } else if (instr.op == Op::Store) {
                std::uint64_t t =
                    (instr.operand2 & ~computer.reset_mask) | computer.set_mask;
                computer.memory[instr.operand1] = t;
            }
        }

        std::uint64_t sum = 0U;
        for (auto& v : computer.memory) {
            sum += v.second;
        }

        return {true, sum};
    }

    std::pair<bool, std::uint64_t> part2() override { return {false, NULL}; }

   private:
    std::vector<Instr> parse_input(std::string const& file_name) {
        std::string raw = read_file_raw(file_name);
        StringView raw_sv(raw);
        std::vector<Instr> instructions = {};

        while (raw_sv.size() > 0U) {
            StringView line_sv = raw_sv.chop_by_delim('\n');
            if (line_sv.starts_with({"mask"})) {
                line_sv.chop_by_delim('=');
                line_sv.trim_left_mut();
                std::uint64_t set_mask = 0U;
                std::uint64_t reset_mask = 0U;
                for (size_t j = 0U; j < line_sv.size(); ++j) {
                    char c = line_sv.data()[j];

                    if (c == '1') {
                        set_mask |= (1ULL << (line_sv.size() - 1 - j));
                    } else if (c == '0') {
                        reset_mask |= (1ULL << (line_sv.size() - 1 - j));
                    }
                }

                instructions.push_back({Op::Mask, set_mask, reset_mask});
            } else {
                line_sv.chop_by_delim('[');
                std::uint64_t addr = line_sv.chop_number<std::uint64_t>();
                line_sv.chop_by_sv({"= "});
                std::uint64_t value = line_sv.chop_number<std::uint64_t>();

                instructions.push_back({Op::Store, addr, value});
                continue;
            }
        }
        return instructions;
    }
};

class Day14Test : public ::testing::Test {
   protected:
    Day14 problem_{"examples/14.txt"};
};

TEST_F(Day14Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day14Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
