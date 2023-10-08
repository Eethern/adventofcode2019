#include "problem.h"
#include <fstream>
#include <chrono>

bool Problem::read_file(std::string const& file_name, std::vector<std::string>& lines)
{
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

void Problem::run()
{
    using namespace std::chrono;
    high_resolution_clock::time_point part1_t1 = high_resolution_clock::now();
    std::pair<bool, std::uint32_t> result_part1{this->part1()};
    high_resolution_clock::time_point part1_t2 = high_resolution_clock::now();
    auto part1_time_span = duration_cast<microseconds>(part1_t2 - part1_t1);

    std::cout << "  | Part1 (" << part1_time_span.count() << "µs): ";
    if (result_part1.first) {
        std::cout << result_part1.second << std::endl;
    } else {
        std::cout << "not implemented " << std::endl;
    }

    high_resolution_clock::time_point part2_t1 = high_resolution_clock::now();
    std::pair<bool, std::uint32_t> result_part2{this->part2()};
    high_resolution_clock::time_point part2_t2 = high_resolution_clock::now();
    auto part2_time_span = duration_cast<microseconds>(part2_t2 - part2_t1);

    std::cout << "  | Part2 (" << part2_time_span.count() << "µs): ";
    if (result_part2.first) {
        std::cout << result_part2.second << std::endl;
    } else {
        std::cout << "not implemented " << std::endl;
    }
}
