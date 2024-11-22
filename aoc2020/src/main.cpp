#include <gtest/gtest.h>
#include <cstdint>
#include <memory>
#include "days.h"
#include "problem.h"

int main() {
    const char* day_str{std::getenv("DAY")};

    if (day_str == nullptr) {
        std::cerr << "Environment variable DAY is not set. Please provide a valid day.";
        return 1;
    }

    size_t supplied_day;
    try {
        supplied_day = std::stoul(day_str);
    } catch (const std::invalid_argument& e) {
        std::cerr << "Invalid day format. Please provide a valid day.";
        return 1;
    } catch (const std::out_of_range& e) {
        std::cerr << "Day value is out of range. Please provide a valid day.";
        return 1;
    }

    std::vector<Problem*> days{};
    days.push_back(new Day01("inputs/01.txt"));
    days.push_back(new Day02("inputs/02.txt"));
    days.push_back(new Day03("inputs/03.txt"));
    days.push_back(new Day04("inputs/04.txt"));
    days.push_back(new Day05("inputs/05.txt"));
    days.push_back(new Day06("inputs/06.txt"));
    days.push_back(new Day07("inputs/07.txt"));
    days.push_back(new Day08("inputs/08.txt"));
    days.push_back(new Day09("inputs/09.txt"));
    days.push_back(new Day10("inputs/10.txt"));
    days.push_back(new Day11("inputs/11.txt"));
    days.push_back(new Day12("inputs/12.txt"));
    days.push_back(new Day13("inputs/13.txt"));
    days.push_back(new Day14("inputs/14.txt"));
    // days.push_back(new Day15("inputs/15.txt"));
    // days.push_back(new Day16("inputs/16.txt"));
    // days.push_back(new Day17("inputs/17.txt"));
    // days.push_back(new Day18("inputs/18.txt"));
    // days.push_back(new Day19("inputs/19.txt"));
    // days.push_back(new Day20("inputs/20.txt"));
    // days.push_back(new Day21("inputs/21.txt"));
    // days.push_back(new Day22("inputs/22.txt"));
    // days.push_back(new Day23("inputs/23.txt"));
    // days.push_back(new Day24("inputs/24.txt"));
    // days.push_back(new Day25("inputs/25.txt"));

    if (supplied_day == 0U) {
        for (Problem *&d : days) {
            std::cout << "Day " << supplied_day+1U << "\n";
            d->run();
            supplied_day++;
        }
    } else if (supplied_day <= days.size()) {
        std::cout << "Day " << supplied_day << std::endl;
        days[supplied_day-1]->run();

    } else {
        std::cerr << "Invalid day specified. Please provide a valid day.";
        return 1;
    }

    return 0;
}

int main_test(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
