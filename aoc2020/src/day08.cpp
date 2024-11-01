#include <gtest/gtest.h>
#include "problem.h"
#include "string_view.h"

typedef enum { NOP = 0, ACC, JMP } OpCode;
typedef enum { ERR_LOOP_DETECTED = 0, HALT, CONTINUE } ExitCode;
typedef struct {
    OpCode opcode;
    int32_t operand;
    bool has_been_executed;
} Instruction;

typedef struct {
    ExitCode exit_code;
    std::vector<int32_t> visited;
} MachineResult;

class Machine {
   public:
    ExitCode tick() {

        if (pc_ >= static_cast<int32_t>(instr_mem_.size())) {
            return ExitCode::HALT;
        }

        Instruction& instr = instr_mem_.at(pc_);
        if (instr.has_been_executed) {
            return ExitCode::ERR_LOOP_DETECTED;
        }

        instr.has_been_executed = true;

        switch (instr.opcode) {
            case OpCode::ACC:
                reg_a_ += instr.operand;
                pc_ += 1;
                break;
            case OpCode::JMP:
                pc_ += instr.operand;
                break;
            default:
                pc_ += 1;
                break;
        }

        return ExitCode::CONTINUE;
    }

    MachineResult run() {
        MachineResult result = {};
        while (true) {
            assert(pc_ >= 0);
            result.visited.push_back(pc_);
            result.exit_code = tick();
            if (result.exit_code == ExitCode::ERR_LOOP_DETECTED ||
                result.exit_code == ExitCode::HALT) {
                break;
            }
        }

        return result;
    }

    void reset_memory() {
        pc_ = 0;
        reg_a_ = 0;
        for (auto& v : instr_mem_) {
            v.has_been_executed = false;
        }
    }

    int32_t pc_;
    int32_t reg_a_;
    std::vector<Instruction> instr_mem_;
};

OpCode sv_to_opcode(StringView const& sv) {
    std::string s = sv.to_string();
    if (s == "nop")
        return OpCode::NOP;
    if (s == "acc")
        return OpCode::ACC;
    if (s == "jmp")
        return OpCode::JMP;

    std::cerr << "Invalid input: " << sv.to_string() << std::endl;
    std::exit(1);
}

class Day08 : public Problem {
   public:
    Day08(const std::string& input) : Problem(input) {}

    std::pair<bool, std::uint64_t> part1() override {
        std::vector<Instruction> instrs = parse_input(input_);
        Machine machine = {0, 0, instrs};
        while (true) {
            assert(machine.pc_ >= 0);
            if (machine.tick() == ExitCode::ERR_LOOP_DETECTED) {
                break;
            }
        }

        return {true, machine.reg_a_};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<Instruction> instrs = parse_input(input_);
        Machine machine = {0, 0, instrs};

        for (std::int32_t i = 0;
             i < static_cast<std::int32_t>(machine.instr_mem_.size()); ++i) {
            Instruction& instr = machine.instr_mem_.at(i);
            OpCode orig_opcode = instr.opcode;
            if (instr.opcode == OpCode::NOP) {
                instr.opcode = OpCode::JMP;
            } else if (instr.opcode == OpCode::JMP) {
                instr.opcode = OpCode::NOP;
            }
            machine.reset_memory();
            MachineResult result = machine.run();

            if (result.exit_code == ExitCode::HALT) {
                break;
            } else if (result.exit_code == ExitCode::ERR_LOOP_DETECTED) {
                machine.instr_mem_.at(i).opcode = orig_opcode;
            } else {
                std::cerr << "Unexpected `continue` encountered" << std::endl;
                exit(1);
            }
        }

        return {true, machine.reg_a_};
    }

   private:
    std::vector<Instruction> parse_input(std::string const& file_name) {
        std::vector<std::string> lines;
        read_file(file_name, lines);

        std::vector<Instruction> instructions = {};
        for (std::string line : lines) {
            StringView sv = {line};
            StringView opcode = sv.chop_by_delim(' ');
            int32_t value = sv.chop_number<int32_t>();

            instructions.push_back({sv_to_opcode(opcode), value, false});
        }
        return instructions;
    }
};

class Day08Test : public ::testing::Test {
   protected:
    Day08 problem_{"examples/08.txt"};
};

TEST_F(Day08Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day08Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
