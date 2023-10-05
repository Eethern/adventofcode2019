#include "problem.h"

class Day01 : public Problem {
public:
    std::pair<bool, std::uint32_t> part1(std::string const& file_name) override;
    std::pair<bool, std::uint32_t> part2(std::string const& file_name) override;
};
