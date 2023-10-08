#include "problem.h"
#include <gtest/gtest.h>
#include <cstdlib>
#include <string>

typedef struct
{
    std::uint64_t right;
    std::uint64_t down;
} Slope;

class Day03 : public Problem
{
public:
    Day03(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        std::vector<std::string> lines;
        if (!read_file(input_, lines)) {
            std::exit(1);
        };

        Slope slope{3U, 1U};
        std::uint64_t encountered_trees = count_collisions(lines, slope);

        return {true, encountered_trees};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        std::vector<std::string> lines;
        if (!read_file(input_, lines)) {
            std::exit(1);
        };

        std::vector<Slope> slopes{
            {1U, 1U}, {3U, 1U}, {5U, 1U}, {7U, 1U}, {1U, 2U},
        };
        uint64_t acc{1U};
        for (Slope const& slope : slopes) {
            std::uint64_t num_collisions{count_collisions(lines, slope)};
            acc *= num_collisions;
        }

        return {true, acc};
    }

private:
    std::uint64_t count_collisions(std::vector<std::string> const& lines,
                                   Slope const& slope)
    {
        std::uint64_t height{static_cast<std::uint64_t>(lines.size())};
        std::uint64_t width{static_cast<std::uint64_t>(lines[0U].size())};
        std::uint64_t x{0U}, y{0U};

        std::uint64_t encountered_trees{0U};
        while (y < height) {
            x = (x + slope.right) % width;
            y += slope.down;
            if (y < height)
                encountered_trees += lines[y][x] == '#' ? 1 : 0;
        }
        return encountered_trees;
    }
};

#define TEST_FILE "example/03.txt"

class Day03Test : public ::testing::Test
{
protected:
    Day03 problem_{TEST_FILE};
};

TEST_F(Day03Test, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day03Test, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
