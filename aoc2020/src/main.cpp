#include <cstdint>
#include <memory>
#include "problem.h"
#include "days.h"

int main()
{
    std::vector<Problem*> days{};
    days.push_back(new Day01("inputs/01.txt"));
    days.push_back(new Day02("inputs/02.txt"));

    size_t day = 1;
    for (auto &&d : days) {
        std::cout << "Day " << day << "\n";
        d->run();
        day++;
    }

    return 0;
}
