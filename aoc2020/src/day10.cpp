#include <gtest/gtest.h>
#include <algorithm>
#include <cstdint>
#include <deque>
#include <iterator>
#include <stack>
#include <string>
#include "problem.h"

typedef std::map<std::uint32_t, std::vector<std::uint32_t>> DAG;
typedef std::map<std::uint32_t, std::uint64_t> Memory;

typedef struct {
    std::uint32_t dest;
    std::uint64_t weight;
} _Edge;

DAG build_dag(std::vector<std::uint32_t> const& numbers) {
    // start on 0
    DAG dag = {};
    for (std::uint32_t i = 0U; i < numbers.size(); ++i) {
        std::uint32_t n = numbers.at(i);
        std::vector<uint32_t> neighbors = {};
        std::uint32_t j = i + 1;
        while (j < numbers.size() && numbers.at(j) <= n + 3) {
            neighbors.push_back(numbers.at(j));
            j++;
        }

        dag.insert({n, neighbors});
    }
    return dag;
}

void print_dag(DAG const& dag) {
    for (auto const& v : dag) {
        std::cout << v.first << ':';
        for (auto& e : v.second) {
            std::cout << e << ',';
        }
        std::cout << std::endl;
    }
}

std::uint64_t count_paths_rec(DAG const& dag, std::uint32_t start,
                              Memory& memory) {
    if (memory.count(start)) {
        return memory.at(start);
    }

    if (dag.at(start).size()) {
        std::uint64_t sum_paths = 0U;
        for (uint32_t t : dag.at(start)) {
            sum_paths += count_paths_rec(dag, t, memory);
        }
        memory.insert({start, sum_paths});
        return sum_paths;
    }
    return 1;
}

class Day10 : public Problem {
   public:
    Day10(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::uint32_t> voltages = parse_input(input_);
        std::sort(voltages.begin(), voltages.end());
        voltages.insert(voltages.begin(), 0U);
        voltages.push_back(voltages.at(voltages.size() - 1) + 3U);

        std::uint32_t num_one_diffs = 0U;
        std::uint32_t num_three_diffs = 0U;
        for (std::uint32_t i = 0U; i < voltages.size() - 1; ++i) {
            std::uint32_t dv = voltages.at(i + 1) - voltages.at(i);
            // assert(dv >= 0U && dv<=3U);
            if (dv == 1)
                num_one_diffs += 1;
            if (dv == 3)
                num_three_diffs += 1;
        }

        return {true, num_one_diffs * num_three_diffs};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::uint32_t> voltages = parse_input(input_);
        std::sort(voltages.begin(), voltages.end());
        voltages.insert(voltages.begin(), 0U);
        voltages.push_back(voltages.at(voltages.size() - 1) + 3U);

        DAG dag = build_dag(voltages);
        Memory memory = {};
        std::uint64_t num_paths = count_paths_rec(dag, voltages.at(0), memory);
        return {true, num_paths};
    }

   private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        std::vector<std::string> lines = {};
        read_file(file_name, lines);

        std::vector<std::uint32_t> voltages = {};
        for (std::string const& line : lines) {
            voltages.push_back(std::stoi(line));
        }

        return voltages;
    }
};

class Day10Test : public ::testing::Test {
   protected:
    Day10 problem_{"examples/day10.txt"};
};

TEST_F(Day10Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day10Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
