#ifndef PROBLEM_H
#define PROBLEM_H

#include <cstdint>
#include <iostream>
#include <vector>
#include <string>

class Problem {
public:
    Problem() = default;
    Problem(const std::string& input) : input_(input) {}

    virtual std::pair<bool, std::uint32_t> part1() {
        return {false, NULL};
    }
    virtual std::pair<bool, std::uint32_t> part2() {
        return {false, NULL};
    }

    void run();

    bool read_file(std::string const& file_name, std::vector<std::string>& lines);

protected:
    std::string input_;
};



#endif /* PROBLEM_H */
