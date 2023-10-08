#include "problem.h"
#include "string_view.h"
#include <fstream>

#include <gtest/gtest.h>
class Day04 : public Problem
{
public:
    Day04(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        std::pair<bool, std::string> result{read_input(input_)};
        if (!result.first) {
            return {false, NULL};
        }
        StringView sv{result.second.c_str()};

        size_t num_valid{0U};
        while (sv.size() > 0U) {
            StringView chunk = sv.chop_by_sv(StringView("\n\n"));
            StringView chunk_copy{chunk.data(),chunk.size()};

            size_t num_fields{0U};
            bool has_cid{false};
            while (chunk.size() > 0U) {
                StringView line{chunk.chop_by_delim('\n')};
                while (line.size() > 0U) {
                    StringView field{line.chop_by_delim(':')};
                    if (field.starts_with({"cid"}))
                        has_cid = true;
                    else
                        num_fields++;

                    line.chop_by_delim(' ');
                }
            }
            if ((num_fields == 7) || (num_fields == 7 && !has_cid)) {
                num_valid++;
            }
        }

        return {true, static_cast<std::uint64_t>(num_valid)};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        return {false, NULL};
    }

private:
    std::pair<bool, std::string> read_input(std::string const& file_name)
    {

        std::ifstream file(file_name);
        if (!file.is_open()) {
            std::cerr << "Error: Could not open the file " << file_name << std::endl;
            return {false, NULL};
        }

        std::string content;
        std::string line;
        while (std::getline(file, line)) {
            content += line;
            content += '\n';
        }

        file.close();

        return {true, content};
    }
};

class Day04Test : public ::testing::Test
{
protected:
    Day04 problem_{"example/04.txt"};
};

TEST_F(Day04Test, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void) result;
}

TEST_F(Day04Test, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void) result;
}
