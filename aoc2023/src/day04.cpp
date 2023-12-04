#include <gtest/gtest.h>

#include <cmath>
#include <string>

#include "problem.h"
#include "string_view.h"

struct Card {
    uint32_t id;
    std::vector<uint32_t> winning_numbers;
    std::vector<uint32_t> picked_numbers;
};

std::vector<uint32_t> parse_numbers(StringView sv) {
    std::vector<uint32_t> out{};
    while (sv.size() > 0U) {
        out.push_back(sv.chop_number<uint32_t>());
        sv = sv.trim_left();
    }
    return out;
}

Card parse_card(std::string const& line) {
    StringView line_sv{line};

    line_sv.chop_by_delim(' ');
    uint32_t id{line_sv.chop_number<uint32_t>()};
    line_sv = line_sv.trim_left();
    line_sv.chop_by_delim(' ');

    StringView winning_sv{line_sv.chop_by_sv({" | "})};
    std::vector<uint32_t> winning_numbers{parse_numbers(winning_sv)};
    std::vector<uint32_t> picked_numbers{parse_numbers(line_sv)};

    return {id, winning_numbers, picked_numbers};
}

std::vector<Card> parse_cards(std::vector<std::string> const& lines) {
    std::vector<Card> out{};
    for (std::string const& line : lines) {
        Card card{parse_card(line)};
        out.push_back(card);
    }

    return out;
}

class Day04 : public Problem {
public:
    Day04(const std::string& input) : Problem(input) {
    }
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        std::vector<Card> cards{parse_cards(lines)};

        uint64_t answer{0U};
        for (Card card : cards) {
            uint32_t num_matches{0U};
            for (uint32_t picked_number : card.picked_numbers) {
                for (uint32_t winning_number : card.winning_numbers) {
                    if (picked_number == winning_number) {
                        num_matches += 1U;
                    }
                }
            }
            answer +=
                static_cast<std::uint64_t>(std::pow(2U, num_matches - 1U));
        }

        return {true, answer};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        std::vector<Card> cards{parse_cards(lines)};

        std::vector<uint64_t> card_counts(cards.size(), 1U);
        size_t curr_card_idx{0U};
        for (Card card : cards) {
            uint64_t num_wins{0U};
            for (uint32_t picked_number : card.picked_numbers) {
                for (uint32_t winning_number : card.winning_numbers) {
                    if (picked_number == winning_number) {
                        num_wins += 1U;
                    }
                }
            }

            for (size_t i{curr_card_idx + 1U};
                 i < std::min(curr_card_idx + num_wins + 1U, cards.size());
                 ++i) {
                card_counts[i] += card_counts[curr_card_idx];
            }
            curr_card_idx += 1U;
        }

        uint64_t answer{0U};
        for (uint64_t count : card_counts) {
            answer += count;
        }

        return {true, answer};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day04Test : public ::testing::Test {
protected:
    Day04 problem_{"examples/04.txt"};
};

TEST_F(Day04Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day04Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
