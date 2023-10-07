#include <cstdint>
#include <memory>
#include "problem.h"
#include "days.h"
int main() {
    std::vector<std::unique_ptr<Problem>> days{};
    days.push_back(std::make_unique<Day01>("inputs/01.txt"));

    for (auto &&d : days) {
        d->run();
    }

    return 0;
}
