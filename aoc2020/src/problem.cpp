#include "problem.h"
#include <chrono>
#include <fstream>

std::string Problem::read_file_raw(std::string const& file_name) const
{
    std::ifstream file(file_name);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open the file " << file_name << std::endl;
        return {};
    }

    // Seek to the end of the file to determine its size
    file.seekg(0, std::ios::end);
    std::streampos file_size = file.tellg();
    file.seekg(0, std::ios::beg);

    // Resize the string to fit the entire file content
    std::string file_content = {};
    file_content.resize(static_cast<std::size_t>(file_size));

    // Read the entire file into the string
    file.read(&file_content[0], file_size);

    file.close();

    return file_content;
}

bool Problem::read_file(std::string const& file_name,
                        std::vector<std::string>& lines) {
    std::ifstream file(file_name);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open the file " << file_name
                  << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(line);
    }

    file.close();

    return true;
}

void Problem::run() {
    using namespace std::chrono;
    // TODO: simplify this
    high_resolution_clock::time_point part1_t1 = high_resolution_clock::now();
    std::pair<bool, std::uint64_t> result_part1{this->part1()};
    high_resolution_clock::time_point part1_t2 = high_resolution_clock::now();
    auto part1_time_span = duration_cast<microseconds>(part1_t2 - part1_t1);

    std::cout << "  | Part1 (" << part1_time_span.count() << "µs): ";
    if (result_part1.first) {
        std::cout << result_part1.second << std::endl;
    } else {
        std::cout << "not implemented " << std::endl;
    }

    high_resolution_clock::time_point part2_t1 = high_resolution_clock::now();
    std::pair<bool, std::uint64_t> result_part2{this->part2()};
    high_resolution_clock::time_point part2_t2 = high_resolution_clock::now();
    auto part2_time_span = duration_cast<microseconds>(part2_t2 - part2_t1);

    std::cout << "  | Part2 (" << part2_time_span.count() << "µs): ";
    if (result_part2.first) {
        std::cout << result_part2.second << std::endl;
    } else {
        std::cout << "not implemented " << std::endl;
    }
}
