#include "problem.h"
#include <gtest/gtest.h>
#include <limits>
#include "string_view.h"

struct Range {
    uint64_t src_start;
    uint64_t dest_start;
    uint64_t length;
};

struct Almanac {
    std::vector<uint64_t> seeds;
    std::vector<std::vector<Range>> maps;
};

std::vector<uint64_t> parse_numbers(StringView& line_sv) {
    std::vector<uint64_t> out{};

    while (line_sv.size() > 0U) {
        uint64_t n{line_sv.chop_number<uint64_t>()};
        out.push_back(n);
        line_sv.trim_left_mut();
    }

    return out;
}

Range parse_range(StringView& range_sv) {

    uint64_t dest_range_start{range_sv.chop_number<uint64_t>()};
    range_sv.trim_left_mut();

    uint64_t src_range_start{range_sv.chop_number<uint64_t>()};
    range_sv.trim_left_mut();

    uint64_t range_len{range_sv.chop_number<uint64_t>()};
    range_sv.trim_left_mut();

    return {src_range_start, dest_range_start, range_len};
}

Almanac parse_almanac(std::string const& raw_text) {
    StringView sv = {raw_text};

    Almanac out{};

    StringView seeds_sv{sv.chop_by_sv({"\n\n"})};
    seeds_sv.chop_by_delim(' ');
    out.seeds = parse_numbers(seeds_sv);


    while (sv.size() > 0U) {
        StringView desc{sv.chop_by_delim('\n')};
        std::string type = desc.chop_by_delim(' ').to_string();

        StringView map_sv{sv.chop_by_sv({"\n\n"})};

        std::vector<Range> ranges{};
        while (map_sv.size() > 0U) {
            StringView range_sv{map_sv.chop_by_delim('\n')};
            ranges.push_back(parse_range(range_sv));
        }

        out.maps.push_back(ranges);
    }

    return out;
}

std::pair<bool, uint64_t> range_translate(Range const& range, uint64_t seed) {
    if (seed >= range.src_start && seed < range.src_start + range.length) {
        return {true, seed - range.src_start + range.dest_start};
    } else {
        return {false, seed};
    }
}

uint64_t seed_translate(std::vector<std::vector<Range>> const& maps, uint64_t seed) {
    uint64_t inter_seed{seed};

    for (std::vector<Range> map : maps) {
        for (Range range : map) {
            std::pair<bool, uint64_t> translate{range_translate(range, inter_seed)};
            if (translate.first) {
                inter_seed = translate.second;
                break;  // assume we don't have overlapping ranges
            }
        }
    }

    return inter_seed;
}

class Day05 : public Problem
{
public:
    Day05(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        std::string raw_text{};
        read_file_raw(input_, raw_text);
        Almanac almanac{parse_almanac(raw_text)};

        uint64_t answer{std::numeric_limits<uint64_t>().max()};
        for (uint64_t seed : almanac.seeds) {
            uint64_t seed_translated{seed_translate(almanac.maps, seed)};
            answer = std::min(answer, seed_translated);
        }

        return {true, answer};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        std::string raw_text{};
        read_file_raw(input_, raw_text);
        Almanac almanac{parse_almanac(raw_text)};

        uint64_t answer{std::numeric_limits<uint64_t>().max()};
        for (size_t i{0U}; i < almanac.seeds.size(); i += 2U) {
            uint64_t seed_start{almanac.seeds.at(i)};
            uint64_t seed_end{seed_start + almanac.seeds.at(i+1)};

            for (uint64_t seed{seed_start}; seed <= seed_end; ++seed) {
                uint64_t seed_translated{seed_translate(almanac.maps, seed)};
                answer = std::min(answer, seed_translated);
            }
        }

        return {true, answer};
    }

private:
    std::vector<uint64_t> parse_input(std::string const& file_name)
    {
        (void) file_name;
        return {};
    }
};

class Day05Test : public ::testing::Test
{
protected:
    Day05 problem_{"examples/05.txt"};
};

TEST_F(Day05Test, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void) result;
}

TEST_F(Day05Test, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void) result;
}
