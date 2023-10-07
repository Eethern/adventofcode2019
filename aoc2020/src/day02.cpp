#include "problem.h"
#include <string.h>
#include <gtest/gtest.h>

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
    std::pair<bool, std::uint32_t> part1() override
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

    std::pair<bool, std::uint32_t> part2() override
    {
        std::vector<Password> passwords{parse_input()};
        size_t valid_passwords{0U};
        for (Password const& pass : passwords) {
            size_t count{0U};

            if (pass.letter == pass.password.at(pass.min-1))
                count++;
            if (pass.letter == pass.password.at(pass.max-1))
                count++;

            if (count == 1)
                valid_passwords++;
        }
        return {true, valid_passwords};
    }

private:
    Password parse_entry(std::string& line)
    {
        // Should probably implement a string view for this
        std::string dash = "-";
        std::string space = " ";

        size_t pos = line.find(dash);
        size_t min = stoi(line.substr(0, pos));
        line.erase(0, pos + dash.length());

        pos = line.find(space);
        size_t max = stoi(line.substr(0, pos));
        line.erase(0, pos + space.length());

        pos = line.find(space);
        char letter = line.substr(0, pos)[0];
        line.erase(0, pos + space.length());

        std::string password = line;

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
    Day02 problem_{"example/02.txt"};
};

TEST_F(Day02Test, part1)
{
    std::pair<bool, std::uint32_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day02Test, part2)
{
    std::pair<bool, std::uint32_t> result{problem_.part2()};
    (void)result;
}
