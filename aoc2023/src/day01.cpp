#include <vector>
#include <cstdint>
#include "problem.h"

#include <gtest/gtest.h>

enum class TokenType
{
    Undefined = 0,
    Digit,
    AlphaDigit,
    EndOfInput,
};

struct Token
{
    TokenType type;
    std::string value;
};

const std::map<std::string, std::string> KEYWORDS_TRANSLATE = {
    {"one", "1"}, {"two", "2"},   {"three", "3"}, {"four", "4"}, {"five", "5"},
    {"six", "6"}, {"seven", "7"}, {"eight", "8"}, {"nine", "9"},
};

std::string tokentype_to_string(TokenType type)
{
    switch (type) {
        case TokenType::Undefined:
            return "Undefined";
        case TokenType::Digit:
            return "Digit";
        case TokenType::AlphaDigit:
            return "AlphaDigit";
        case TokenType::EndOfInput:
            return "<eol>";
    }
    return "WARNING: UNKNOWN token";
}

class Tokenizer
{
public:
    Tokenizer(const std::string& input) : input_(input), cursor_(0U)
    {
    }

    std::pair<bool, Token> next_token()
    {
        if (cursor_ >= input_.size()) {
            return {true, {TokenType::EndOfInput, "<end>"}};
        }

        char current_char{input_[cursor_]};

        if (std::isdigit(current_char)) {
            ++cursor_;
            return {true, {TokenType::Digit, std::string(1, current_char)}};
        } else if (std::isalpha(current_char)) {
            return read_alpha_digit();
        } else {
            return {false, {TokenType::Undefined, ""}};
        }
    }

    std::vector<Token> tokenize()
    {
        std::vector<Token> tokens{};
        Token next{TokenType::Undefined, ""};
        while (next.type != TokenType::EndOfInput) {
            std::pair<bool, Token> n{next_token()};

            if (n.first && n.second.type != TokenType::EndOfInput) {
                tokens.push_back(n.second);
            }

            next = n.second;
        }
        return tokens;
    }

private:
    std::pair<bool, Token> read_alpha_digit()
    {
        std::stringstream stream;
        char curr{input_[cursor_]};
        while (cursor_ < input_.size() && std::isalpha(curr)) {
            stream << curr;
            ++cursor_;
            curr = input_[cursor_];

            for (auto it = KEYWORDS_TRANSLATE.begin();
                 it != KEYWORDS_TRANSLATE.end(); it++) {
                std::string const& key{it->first};
                if (stream.str() == key) {
                    cursor_ += -key.size() + 2;
                    return {
                        true,
                        {TokenType::AlphaDigit, KEYWORDS_TRANSLATE.at(key)}};
                }

                if (stream.str().find(key) != std::string::npos) {
                    cursor_ += -key.size() + 2;
                    return {
                        true,
                        {TokenType::AlphaDigit, KEYWORDS_TRANSLATE.at(key)}};
                }
            }
        }

        return {false, {TokenType::Undefined, ""}};
    }

    std::string input_;
    std::size_t cursor_;
};

class Day01 : public Problem
{
public:
    Day01(const std::string& input) : Problem(input)
    {
    }

    uint32_t two_digits_to_uint32(char a, char b) const
    {
        if (!isdigit(a) || !isdigit(b)) {
            std::cerr << "Invalid digit: " << a << "," << b << std::endl;
            exit(0);
        }
        uint32_t out{10U * (a - '0') + (b - '0')};
        return out;
    }

    std::pair<bool, std::uint64_t> part1() override
    {
        std::vector<std::string> lines;
        this->read_file(this->input_, lines);

        uint32_t acc{0U};
        for (const std::string& line : lines) {
            std::vector<char> number{};
            for (const char c : line) {
                if (std::isdigit(c)) {
                    number.push_back(c);
                }
            }

            acc += two_digits_to_uint32(number.front(), number.back());
        }

        return {true, acc};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        std::vector<std::string> lines;
        this->read_file(this->input_, lines);

        uint32_t acc{0U};
        for (const std::string& line : lines) {
            Tokenizer tokenizer{line};
            std::vector<Token> tokens{tokenizer.tokenize()};
            acc += two_digits_to_uint32(tokens.front().value.at(0U),
                                        tokens.back().value.at(0U));
        }

        return {true, acc};
    }
};

class Day01Test : public ::testing::Test
{
};

TEST_F(Day01Test, part1)
{
    Day01 problem_{"examples/01a.txt"};
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day01Test, part2)
{
    Day01 problem_{"examples/01b.txt"};
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
