#ifndef PROBLEM_H
#define PROBLEM_H

#include <cstdint>
#include <iostream>
#include <vector>
#include <string>

class Problem {
public:
    Problem() = default;

    virtual std::pair<bool, std::uint32_t> part1(std::string const& file_name) {
        static_cast<void>(file_name);
        return {false, NULL};
    }
    virtual std::pair<bool, std::uint32_t> part2(std::string const& file_name) {
        static_cast<void>(file_name);
        return {false, NULL};
    }

    void run(std::string const& file_name);

    bool read_file(std::string const& file_name, std::vector<std::string>& lines);
};



#endif /* PROBLEM_H */
