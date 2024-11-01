#include "problem.h"
#include "string_view.h"
#include <string.h>
#include <gtest/gtest.h>
#include <string>

typedef struct
{
    char letter;
    size_t min;
    size_t max;
    std::string password;
} Password;

class Day02 : public Problem
{
public:
    Day02(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        std::vector<Password> passwords{parse_input()};
        size_t valid_passwords{0U};
        for (Password const& pass : passwords) {
            size_t count{0U};
            for (char letter : pass.password) {
                if (letter == pass.letter)
                    count++;
                if (count > pass.max)
                    break;
            }

            if (count >= pass.min && count <= pass.max)
                valid_passwords++;
        }
        return {true, valid_passwords};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        std::vector<Password> passwords{parse_input()};
        size_t valid_passwords{0U};
        for (Password const& pass : passwords) {
            size_t count{0U};

            if (pass.letter == pass.password.at(pass.min - 1))
                count++;
            if (pass.letter == pass.password.at(pass.max - 1))
                count++;

            if (count == 1)
                valid_passwords++;
        }
        return {true, valid_passwords};
    }

private:
    Password parse_entry(std::string& line)
    {
        StringView sv{line.c_str()};

        sv = sv.trim_left();
        std::size_t min = std::stoi(sv.chop_by_delim('-').data());
        std::size_t max = std::stoi(sv.chop_by_delim(' ').data());
        char letter = sv.chop_by_delim(':')[0];
        sv.chop_by_delim(' ');
        std::string password(sv.data());

        return {letter, min, max, password};
    }
    std::vector<Password> parse_input()
    {
        std::vector<std::string> lines;
        this->read_file(input_, lines);

        std::vector<Password> output{};
        for (std::string& line : lines) {
            output.push_back(parse_entry(line));
        }
        return output;
    }
};

class Day02Test : public ::testing::Test
{
protected:
    Day02 problem_{"examples/02.txt"};
};

TEST_F(Day02Test, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day02Test, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
