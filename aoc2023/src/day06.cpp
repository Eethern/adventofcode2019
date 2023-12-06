#include <gtest/gtest.h>
#include <math.h>

#include <cmath>
#include <sstream>

#include "problem.h"
#include "string_view.h"

struct Race {
    int64_t duration;
    int64_t distance;
};

std::vector<Race> parse_races(std::vector<std::string> const& lines) {
    std::vector<Race> out{};
    StringView time_sv{lines[0]};
    time_sv.chop_by_delim(':');
    time_sv.trim_left_mut();

    StringView dist_sv{lines[1]};
    dist_sv.chop_by_delim(':');
    dist_sv.trim_left_mut();

    while (time_sv.size() > 0U && dist_sv.size() > 0U) {
        Race race{};
        race.duration = time_sv.chop_number<int64_t>();
        race.distance = dist_sv.chop_number<int64_t>();
        time_sv.trim_left_mut();
        dist_sv.trim_left_mut();

        out.push_back(race);
    }

    return out;
}

Race parse_race_kerning(std::vector<std::string> const& lines) {
    StringView time_sv{lines[0]};
    time_sv.chop_by_delim(':');
    time_sv.trim_left_mut();

    StringView dist_sv{lines[1]};
    dist_sv.chop_by_delim(':');
    dist_sv.trim_left_mut();

    Race race{};
    std::stringstream dist_stream{};
    for (char c : dist_sv) {
        if (isdigit(c)) {
            dist_stream << c;
        }
    }

    std::stringstream time_stream{};
    for (char c : time_sv) {
        if (isdigit(c)) {
            time_stream << c;
        }
    }

    dist_stream >> race.distance;
    time_stream >> race.duration;

    return race;
}

class Day06 : public Problem {
public:
    Day06(const std::string& input) : Problem(input) {
    }
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        std::vector<Race> races{parse_races(lines)};

        int64_t answer{1U};
        for (Race const& race : races) {
            uint64_t num_wins{0U};
            for (int64_t dur{0}; dur <= race.duration; ++dur) {
                int64_t achieved{(race.duration - dur) * dur};
                if (achieved > race.distance) {
                    num_wins++;
                }
            }
            answer *= num_wins;
        }

        return {true, static_cast<uint64_t>(answer)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<std::string> lines;
        read_file(input_, lines);
        Race race{parse_race_kerning(lines)};

        double t{static_cast<double>(race.duration)};
        double d{static_cast<double>(race.distance)};

        double temp{std::sqrt(std::pow(t, 2.0) - 4.0 * d)};
        int64_t lower = static_cast<int64_t>(floor((t - temp) / 2.0)) + 1;
        int64_t upper = static_cast<int64_t>(ceil((t + temp) / 2.0));

        int64_t real_lower{lower};
        for (int64_t dur{lower}; dur <= race.duration && dur <= upper; ++dur) {
            int64_t achieved{(race.duration - dur) * dur};
            if (achieved > race.distance) {
                real_lower = dur;
                break;
            }
        }

        int64_t real_upper{lower};

        for (int64_t dur{upper}; dur >= real_lower; --dur) {
            int64_t achieved{(race.duration - dur) * dur};
            if (achieved > race.distance) {
                real_upper = dur;
                break;
            }
        }
        uint64_t answer{static_cast<uint64_t>(real_upper - real_lower + 1U)};

        return {true, answer};
    }

private:
    std::vector<uint64_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day06Test : public ::testing::Test {
protected:
    Day06 problem_{"examples/06.txt"};
};

TEST_F(Day06Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day06Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
