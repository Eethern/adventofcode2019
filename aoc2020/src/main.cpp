#include <cstdint>
#include <memory>
#include "problem.h"
#include "days.h"
#include <gtest/gtest.h>

int main()
{
    std::vector<Problem *> days{};
    days.push_back(new Day01("inputs/01.txt"));
    days.push_back(new Day02("inputs/02.txt"));
    days.push_back(new Day03("inputs/03.txt"));
    days.push_back(new Day04("inputs/04.txt"));
    days.push_back(new Day05("inputs/05.txt"));
    days.push_back(new Day06("inputs/06.txt"));

    size_t day = 1;
    for (Problem *&d : days) {
        std::cout << "Day " << day << "\n";
        d->run();
        day++;
    }

    return 0;
}

int main_test(int argc, char **argv)
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
