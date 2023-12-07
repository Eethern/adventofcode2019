#include <gtest/gtest.h>

#include <algorithm>

#include "problem.h"
#include "string_view.h"

enum HandType {
    HighCard = 0,  // 1 1 1 1 1
    OnePair,       // 2 1 1 1
    TwoPair,       // 2 2 1
    ThreeOfAKind,  // 3 1 1
    FullHouse,     // 3 2
    FourOfAKind,   // 4 1
    FiveOfAKind    // 5
};

const std::map<char, size_t> CARD_MAP{
    {'2', 2}, {'3', 3},  {'4', 4},  {'5', 5},  {'6', 6},  {'7', 7},  {'8', 8},
    {'9', 9}, {'T', 10}, {'J', 11}, {'Q', 12}, {'K', 13}, {'A', 14},
};

const std::map<char, size_t> JOKER_CARD_MAP{
    {'J', 1}, {'2', 2}, {'3', 3},  {'4', 4},  {'5', 5},  {'6', 6},  {'7', 7},
    {'8', 8}, {'9', 9}, {'T', 10}, {'Q', 11}, {'K', 12}, {'A', 13},
};

constexpr size_t HAND_SIZE{5U};

struct Hand {
    std::string cards;
    uint32_t bid;
};

struct Quality {
    Hand hand;
    HandType qual;
};

Hand parse_hand(std::string const& line) {
    StringView line_sv{line};

    Hand hand{line_sv.chop_by_delim(' ').to_string(),
              line_sv.chop_number<uint32_t>()};
    return hand;
}

std::vector<std::pair<char, size_t> > count_cards(Hand const& hand) {
    std::vector<std::pair<char, size_t> > counts{};
    for (char c : hand.cards) {
        bool found_char{false};
        for (std::pair<char, size_t>& entry : counts) {
            if (entry.first == c) {
                entry.second += 1U;
                found_char = true;
                break;
            }
        }
        if (!found_char) {
            counts.push_back({c, 1U});
        }
    }

    // sort the counts
    auto pair_comparator = [](const std::pair<char, size_t>& a,
                              const std::pair<char, size_t>& b) {
        return a.second > b.second;
    };

    std::sort(counts.begin(), counts.end(), pair_comparator);

    return counts;
}

HandType eval_hand(Hand const& hand) {
    std::vector<std::pair<char, size_t> > counts{count_cards(hand)};
    size_t first{counts.at(0).second};
    if (first == 5U) {
        return FiveOfAKind;
    }

    size_t second{counts.at(1).second};

    if (first == 4U) {
        return FourOfAKind;
    } else if (first == 3U) {
        if (second == 2U) {
            return FullHouse;
        } else {
            return ThreeOfAKind;
        }
    } else if (first == 2U) {
        if (second == 2U) {
            return TwoPair;
        } else {
            return OnePair;
        }
    } else {
        return HighCard;
    }
}

size_t count_jokers(std::vector<std::pair<char, size_t>> counts) {
    size_t n_jokers{0U};
    for (std::pair<char, size_t> entry : counts) {
        if (entry.first == 'J') {
            n_jokers += entry.second;
            break;
        }
    }

    return n_jokers;
}

HandType joker_eval(Hand const& hand) {
    std::vector<std::pair<char, size_t> > counts{count_cards(hand)};
    size_t n_jokers{count_jokers(counts)};

    size_t first{counts.at(0).second};
    if (first == 5U) {
        return FiveOfAKind;
    }

    size_t second{counts.at(1).second};

    if (counts.at(0).first == 'J') {
        first = second + n_jokers;
    } else {
        first += n_jokers;
    }

    if (first == 5U) {
        return FiveOfAKind;
    }

    if (first == 4U) {
        return FourOfAKind;
    } else if (first == 3U) {
        if (second == 2U) {
            return FullHouse;
        } else {
            return ThreeOfAKind;
        }
    } else if (first == 2U) {
        if (second == 2U) {
            return TwoPair;
        } else {
            return OnePair;
        }
    } else {
        return HighCard;
    }
}

uint64_t rank_all_hands(std::vector<Quality> const& hands) {
    uint64_t rank{1U};
    uint64_t answer{0U};
    for (Quality const& quality : hands) {
        answer += static_cast<uint64_t>(quality.hand.bid) * rank;
        rank++;
    }

    return answer;
}

class Day07 : public Problem {
public:
    Day07(const std::string& input) : Problem(input) {
    }
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);

        std::vector<Quality> hands{};
        for (std::string const& line : lines) {
            Hand hand{parse_hand(line)};
            HandType qual{eval_hand(hand)};

            hands.push_back({hand, qual});
        }

        auto comparator = [](Quality const& a, Quality const& b) {
            if (a.qual == b.qual) {
                for (size_t i{0U}; i < HAND_SIZE; ++i) {
                    size_t a_val{CARD_MAP.at(a.hand.cards[i])};
                    size_t b_val{CARD_MAP.at(b.hand.cards[i])};
                    if (a_val < b_val) {
                        return true;
                    } else if (a_val > b_val) {
                        return false;
                    }
                }
                return true;
            }

            return a.qual < b.qual;
        };

        std::sort(hands.begin(), hands.end(), comparator);

        uint64_t answer{rank_all_hands(hands)};

        return {true, static_cast<uint64_t>(answer)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        std::vector<Quality> hands{};

        auto comparator = [](Quality const& a, Quality const& b) {
            if (a.qual == b.qual) {
                for (size_t i{0U}; i < HAND_SIZE; ++i) {
                    size_t a_val{JOKER_CARD_MAP.at(a.hand.cards[i])};
                    size_t b_val{JOKER_CARD_MAP.at(b.hand.cards[i])};
                    if (a_val < b_val) {
                        return true;
                    } else if (a_val > b_val) {
                        return false;
                    }
                }
                return true;
            }

            return a.qual < b.qual;
        };

        for (std::string const& line : lines) {
            Hand hand{parse_hand(line)};
            HandType qual{joker_eval(hand)};
            hands.push_back({hand, qual});
        }

        std::sort(hands.begin(), hands.end(), comparator);

        uint64_t answer{rank_all_hands(hands)};

        return {true, answer};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day07Test : public ::testing::Test {
protected:
    Day07 problem_{"examples/07.txt"};
};

TEST_F(Day07Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day07Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
