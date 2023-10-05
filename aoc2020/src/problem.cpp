#include "problem.h"
#include <fstream>

bool Problem::read_file(std::string const& file_name, std::vector<std::string>& lines) {
    std::ifstream file(file_name);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open the file " << file_name << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(line);
    }

    file.close();
    return true;
}

void Problem::run(std::string const& file_name)
{
    std::pair<bool, std::uint32_t> result_part1{this->part1(file_name)};

    if (result_part1.first) {
        std::cout << "Part1: " << result_part1.second << std::endl;
    } else {
        std::cout << "Part1: not implemented" << std::endl;
    }

    std::pair<bool, std::uint32_t> result_part2{this->part2(file_name)};
    if (result_part2.first) {
        std::cout << "Part2: " << result_part2.second << std::endl;
    } else {
        std::cout << "Part2: not implemented" << std::endl;
    }
}
