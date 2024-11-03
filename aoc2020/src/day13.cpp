#include <gtest/gtest.h>
#include <limits>
#include "problem.h"
#include "string_view.h"

typedef struct {
    std::int64_t arrival_time;
    std::vector<std::int64_t> buss_ids;
} TimeInfo;

typedef struct {
    std::int64_t rem;
    std::int64_t mod;
} Equation;

std::int64_t positive_mod(std::int64_t a, std::int64_t b) {
    return (a % b + b) % b;
}

std::int64_t extended_euclidean(std::int64_t a, std::int64_t mod) {
    std::int64_t m0 = mod;
    std::int64_t x0 = 0;
    std::int64_t x1 = 1;

    while (a > 1) {
        std::int64_t q = a / mod;
        std::int64_t temp = mod;

        mod = a % mod;
        a = temp;

        std::int64_t new_x = x1 - q * x0;
        x1 = x0;
        x0 = new_x;
    }

    if (x1 < 0) {
        x1 += m0;
    }
    return x1;
}

std::int64_t chinese_remainder_theorem(std::vector<Equation> const& eqs) {
    // Solve for example the following system of congruences
    //   t ===  0 (mod 7)
    //   t === -1 (mod 13)
    //   t === -4 (mod 59)
    //   t === -6 (mod 31)
    //   t === -7 (mod 19)

    // Find the product of all moduli (N)
    std::int64_t N = 1;
    for (auto const& eq : eqs) {
        N *= eq.mod;
    }

    // Calculate t using the CRT formula
    std::int64_t t = 0;
    for (auto const& eq : eqs) {
        std::int64_t Ni = N / eq.mod;
        std::int64_t inv = extended_euclidean(Ni, eq.mod);
        t += eq.rem * Ni * inv;
    }

    // Ensure t is within the range [0, N-1]
    return positive_mod(t, N);
}

class Day13 : public Problem {
   public:
    Day13(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        TimeInfo time_info = parse_input(input_);
        std::int64_t earliest_buss_id = 0U;
        std::int64_t minutes_to_wait = std::numeric_limits<std::int64_t>::max();
        for (auto buss_id : time_info.buss_ids) {
            if (buss_id == 0)
                continue;
            std::int64_t minutes = buss_id - time_info.arrival_time % buss_id;
            if (minutes_to_wait > minutes) {
                minutes_to_wait = minutes;
                earliest_buss_id = buss_id;
            }
        }
        return {true, minutes_to_wait * earliest_buss_id};
    }

    std::pair<bool, std::uint64_t> part2() override {
        TimeInfo time_info = parse_input(input_);

        std::vector<Equation> eqs = {};
        for (std::size_t i = 0U; i < time_info.buss_ids.size(); ++i) {
            if (time_info.buss_ids[i] == 0)
                continue;

            std::int64_t positive_rem = positive_mod(
                -static_cast<std::int64_t>(i), time_info.buss_ids[i]);

            Equation eq = {positive_rem, time_info.buss_ids[i]};
            eqs.push_back(eq);
        }

        std::int64_t answer = chinese_remainder_theorem(eqs);

        return {true, answer};
    }

   private:
    TimeInfo parse_input(std::string const& file_name) {
        std::string raw = read_file_raw(file_name);
        StringView sv = {raw};

        std::int64_t arrival_time =
            sv.chop_by_delim('\n').chop_number<std::int64_t>();
        std::vector<std::int64_t> buss_ids = {};
        while (!sv.empty()) {
            if (sv.starts_with({"x"})) {
                buss_ids.push_back(0);
            } else {
                buss_ids.push_back(sv.chop_number<std::int64_t>());
            }
            sv.chop_by_delim(',');
        }

        return {arrival_time, buss_ids};
    }
};

class Day13Test : public ::testing::Test {
   protected:
    Day13 problem_{"examples/13.txt"};
};

TEST_F(Day13Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day13Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
