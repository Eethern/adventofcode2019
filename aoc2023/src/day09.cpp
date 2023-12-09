#include <gtest/gtest.h>

#include <stack>

#include "problem.h"
#include "string_view.h"

std::vector<int64_t> parse_seq(std::string const& line) {
    StringView line_sv{line};
    std::vector<int64_t> seq{};
    while (line_sv.size() > 0) {
        seq.push_back(line_sv.chop_number<int64_t>());
        line_sv.trim_left_mut();
    }
    return seq;
}

std::stack<std::vector<int64_t> > get_intermediate_stack(
    std::vector<int64_t> const& seq) {
    bool all_zero{false};
    std::stack<std::vector<int64_t> > q{};
    q.push(seq);

    while (!all_zero) {
        all_zero = true;
        std::vector<int64_t> next_level{};

        for (size_t i{0U}; i < q.top().size() - 1U; ++i) {
            int64_t cur{q.top()[i]};
            int64_t next{q.top()[i + 1U]};
            int64_t diff{next - cur};

            next_level.push_back(next - cur);

            if (diff != 0U) {
                all_zero = false;
            }
        }
        q.push(next_level);
    }

    return q;
}

int64_t get_next_value(std::stack<std::vector<int64_t> > q) {
    q.top().push_back(0U);
    int64_t answer{0U};
    while (q.size() > 1U) {
        int64_t a = q.top().back();
        q.pop();
        int64_t b = q.top().back();
        answer = a + b;
        q.top().push_back(answer);
    }
    return answer;
}

int64_t get_prev_value(std::stack<std::vector<int64_t> > q) {
    q.top().insert(q.top().begin(), 0);
    int64_t answer{0U};
    while (q.size() > 1U) {
        int64_t a = q.top().front();
        q.pop();
        int64_t b = q.top().front();
        answer = b - a;
        q.top().insert(q.top().begin(), answer);
    }
    return answer;
}

class Day09 : public Problem {
public:
    Day09(const std::string& input) : Problem(input) {
    }
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines{};
        read_file(input_, lines);

        int64_t answer{0U};
        for (std::string const& line : lines) {
            std::vector<int64_t> seq{parse_seq(line)};
            std::stack<std::vector<int64_t> > q{get_intermediate_stack(seq)};
            answer += get_next_value(q);
        }

        return {true, static_cast<uint64_t>(answer)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines{};
        read_file(input_, lines);

        int64_t answer{0U};
        for (std::string const& line : lines) {
            std::vector<int64_t> seq{parse_seq(line)};
            std::stack<std::vector<int64_t> > q{get_intermediate_stack(seq)};
            answer += get_prev_value(q);
        }

        return {true, static_cast<uint64_t>(answer)};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day09Test : public ::testing::Test {
protected:
    Day09 problem_{"examples/09.txt"};
};

TEST_F(Day09Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day09Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
