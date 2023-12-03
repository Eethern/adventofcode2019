#include <gtest/gtest.h>

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <vector>

#include "problem.h"
#include "string_view.h"

const std::map<std::string, char> KEYWORDS_TRANSLATE = {
    {"one", '1'}, {"two", '2'},   {"three", '3'}, {"four", '4'}, {"five", '5'},
    {"six", '6'}, {"seven", '7'}, {"eight", '8'}, {"nine", '9'},
};

const std::map<std::string, char> KEYWORDS_TRANSLATE_REV = {
    {"eno", '1'}, {"owt", '2'},   {"eerht", '3'}, {"ruof", '4'}, {"evif", '5'},
    {"xis", '6'}, {"neves", '7'}, {"thgie", '8'}, {"enin", '9'},
};

char find_first_digit(std::string const& line,
                      std::map<std::string, char> const& translation_map) {
    for (size_t i{0U}; i < line.length(); ++i) {
        char c = line.at(i);
        if (isdigit(c)) {
            return c;
        } else {
            StringView line_sv{line.c_str()};
            StringView substr_sv{line_sv.chop_while(isalpha)};
            size_t chopped_size{substr_sv.size()};

            while (substr_sv.size() > 2U) {
                for (auto it = translation_map.begin();
                     it != translation_map.end(); it++) {
                    std::string const& key{it->first};
                    StringView key_sv{key.c_str()};
                    if (substr_sv.starts_with(key_sv)) {
                        return it->second;
                    }
                }
                substr_sv.forward_mut(1);
            }
            i += chopped_size - 1U;
        }
    }

    return '_';  // found nothing
}

class Day01 : public Problem {
public:
    Day01(const std::string& input) : Problem(input) {
    }

    uint32_t two_digits_to_uint32(char a, char b) const {
        if (!isdigit(a) || !isdigit(b)) {
            std::cerr << "Invalid digit: " << a << "," << b << std::endl;
            exit(0);
        }
        uint32_t out{10U * (a - '0') + (b - '0')};
        return out;
    }

    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        uint32_t acc{0U};
        for (const std::string& line : lines) {
            uint32_t first{0U};
            for (const char c : line) {
                if (std::isdigit(c)) {
                    first = c;
                    break;
                }
            }

            uint32_t last{0U};
            for (int32_t i{static_cast<int32_t>(line.length()) - 1}; i >= 0;
                 --i) {
                char c = line.at(static_cast<size_t>(i));
                if (std::isdigit(c)) {
                    last = c;
                    break;
                }
            }

            acc += two_digits_to_uint32(first, last);
        }

        return {true, acc};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        uint32_t acc{0U};
        for (std::string& line : lines) {
            char first{find_first_digit(line, KEYWORDS_TRANSLATE)};
            std::string line_rev(line.rbegin(), line.rend());
            char last{find_first_digit(line_rev, KEYWORDS_TRANSLATE_REV)};
            acc += two_digits_to_uint32(first, last);
        }

        return {true, acc};
    }
};

class Day01Test : public ::testing::Test {};

TEST_F(Day01Test, part1) {
    Day01 problem_{"examples/01a.txt"};
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day01Test, part2) {
    Day01 problem_{"examples/01b.txt"};
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
