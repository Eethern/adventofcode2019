#include "problem.h"
#include "string_view.h"
#include <cctype>
#include <fstream>
#include <string>

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
            StringView chunk_copy{chunk.data(), chunk.size()};

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
        std::pair<bool, std::string> result{read_input(input_)};
        if (!result.first) {
            return {false, NULL};
        }
        StringView sv{result.second.c_str()};

        size_t num_valid{0U};
        while (sv.size() > 0U) {
            StringView chunk = sv.chop_by_sv(StringView("\n\n"));
            StringView chunk_copy{chunk.data(), chunk.size()};

            size_t num_fields{0U};
            bool has_cid{false};
            bool all_valid_fields = true;
            while (chunk.size() > 0U) {
                StringView line{chunk.chop_by_delim('\n')};
                while (line.size() > 0U) {
                    StringView field{line.chop_by_delim(':')};
                    if (field.starts_with({"cid"}))
                        has_cid = true;
                    else
                        num_fields++;

                    StringView value{line.chop_by_delim(' ')};
                    if (!valid_field(field, value)) {
                        all_valid_fields = false;
                    }
                }
            }
            if (all_valid_fields &&
                ((num_fields == 7) || (num_fields == 7 && !has_cid))) {
                num_valid++;
            }
        }

        return {true, static_cast<std::uint64_t>(num_valid)};
    }

private:
    bool validate_number(std::string const& value, std::int32_t min,
                         std::int32_t max, std::size_t len) const
    {
        if (value.size() != len) {
            return false;
        }
        for (char c : value) {
            if (!std::isdigit(c)) {
                return false;
            }
        }
        std::int32_t num{std::stoi(value)};
        if (num < min || num > max) {
            return false;
        }

        return true;
    }
    bool valid_field(StringView const& field, StringView const& value) const
    {
        std::string const f{std::string(field.begin(), field.begin() + 3)};
        std::string const v{value.to_string()};

        if (f == "byr") {
            return validate_number(v, 1920, 2002, 4);
        }

        if (f == "iyr") {
            return validate_number(v, 2010, 2020, 4);
        }

        if (f == "eyr") {
            return validate_number(v, 2020, 2030, 4);
        }

        if (f == "hgt") {
            if (value.ends_with({"cm"}))
                return validate_number(v.substr(0, v.length() - 2), 150, 193,
                                       3);
            if (value.ends_with({"in"}))
                return validate_number(v.substr(0, v.length() - 2), 59, 76, 2);
            else {
                return false;
            }
        }

        if (f == "hcl") {
            if (v[0] != '#') {
                return false;
            }
            for (char c : v.substr(1, v.length())) {
                if (!std::isalnum(c)) {
                    return false;
                }
            }
            return true;
        }

        if (f == "ecl") {
            if (!(v == "amb" || v == "blu" || v == "brn" || v == "gry" ||
                  v == "grn" || v == "hzl" || v == "oth")) {
                return false;
            }
            return true;
        }

        if (f == "pid") {
            return validate_number(v, 0, 999999999, 9);
        }

        if (f == "cid") {
            return true;
        }

        std::cerr << "Weird field encountered " << field.to_string() << ","
                  << value.to_string() << std::endl;
        return false;
    }

private:
    std::pair<bool, std::string> read_input(std::string const& file_name)
    {
        std::ifstream file(file_name);
        if (!file.is_open()) {
            std::cerr << "Error: Could not open the file " << file_name
                      << std::endl;
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
    Day04 problem_{"examples/04.txt"};
};

TEST_F(Day04Test, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day04Test, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
