#ifndef PROBLEM_H
#define PROBLEM_H

#include <cstdint>
#include <iostream>
#include <vector>
#include <string>

class Problem {
public:
    Problem() = default;

    virtual std::pair<bool, std::uint32_t> part1(std::string const& file_name) = 0;
    virtual std::pair<bool, std::uint32_t> part2(std::string const& file_name) = 0;

    void run(std::string const& file_name);

    bool read_file(std::string const& file_name, std::vector<std::string>& lines);
};



#endif /* PROBLEM_H */
