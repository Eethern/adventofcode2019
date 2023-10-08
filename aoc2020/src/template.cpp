#include "problem.h"
#include <gtest/gtest.h>
class Template : public Problem
{
public:
    Template(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        return {false, NULL};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        return {false, NULL};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name)
    {
        (void) file_name;
        return {};
    }
};

class TemplateTest : public ::testing::Test
{
protected:
    Template problem_{"example/template.txt"};
};

TEST_F(TemplateTest, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void) result;
}

TEST_F(TemplateTest, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void) result;
}
