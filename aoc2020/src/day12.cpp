#include <gtest/gtest.h>
#include <cassert>
#include <cmath>
#include "problem.h"
#include "string_view.h"

typedef enum { North = 0, South, East, West, Left, Right, Forward } CommandKind;

typedef struct {
    CommandKind kind;
    std::int32_t value;
} Command;

typedef struct {
    std::int32_t x;
    std::int32_t y;
} Vec;

typedef struct {
    Vec position;
    std::int32_t degrees;
    Vec waypoint;
} Ship;

constexpr Vec COMMANDKIND_TO_VEC[] = {
    {0, 1},
    {0, -1},
    {1, 0},
    {-1, 0},
    {0, 0},
    {0, 0},
    {0, 0}};

Vec dir_from_heading(std::int32_t heading) {
    Vec out = {};
    switch (heading) {
        case 0:
            out = COMMANDKIND_TO_VEC[CommandKind::East];
            break;
        case 90:
            out = COMMANDKIND_TO_VEC[CommandKind::North];
            break;
        case 180:
            out = COMMANDKIND_TO_VEC[CommandKind::West];
            break;
        case 270:
            out = COMMANDKIND_TO_VEC[CommandKind::South];
            break;
        default:
            assert(0 && "unreachable");
            break;
    }
    return out;
}

Vec rotate_vector(Vec p, std::int32_t degrees) {
    Vec out = {};
    float rad = static_cast<float>(degrees) * static_cast<float>(M_PI) / 180.0f;  // Convert degrees to radians
    float crad = cosf(rad);
    float srad = sinf(rad);

    out.x = static_cast<std::int32_t>(std::round(static_cast<float>(p.x) * crad - static_cast<float>(p.y) * srad));
    out.y = static_cast<std::int32_t>(std::round(static_cast<float>(p.x) * srad + static_cast<float>(p.y) * crad));

    return out;
}

std::int32_t good_mod(std::int32_t a, std::int32_t b) {
    return (a % b + b) % b;
}

class Day12 : public Problem {
   public:
    Day12(const std::string& input) : Problem(input) {}
    std::pair<bool, std::uint64_t> part1() override {
        std::vector<Command> commands = parse_input(input_);
        Ship ship = {};
        for (Command const& command : commands) {
            Vec dir = COMMANDKIND_TO_VEC[command.kind];
            switch (command.kind) {
                case North:
                case South:
                case West:
                case East:
                    ship.position.x += dir.x * command.value;
                    ship.position.y += dir.y * command.value;
                    break;
                case Left:
                    ship.degrees = good_mod(
                        ship.degrees + static_cast<std::int32_t>(command.value),
                        360);
                    break;
                case Right:
                    ship.degrees = good_mod(
                        ship.degrees - static_cast<std::int32_t>(command.value),
                        360);
                    break;
                case Forward:
                    Vec dir = dir_from_heading(ship.degrees);
                    ship.position.x += dir.x * command.value;
                    ship.position.y += dir.y * command.value;
                    break;
            }
        }
        return {true, abs(ship.position.x) + abs(ship.position.y)};
    }

    std::pair<bool, std::uint64_t> part2() override {
        std::vector<Command> commands = parse_input(input_);
        Ship ship = {{0, 0}, 0, {10, 1}};
        for (Command const& command : commands) {
            Vec dir = COMMANDKIND_TO_VEC[command.kind];
            switch (command.kind) {
                case North:
                case South:
                case West:
                case East:
                    ship.waypoint.x += dir.x * command.value;
                    ship.waypoint.y += dir.y * command.value;
                    break;
                case Left:
                    ship.waypoint = rotate_vector(ship.waypoint, command.value);
                    break;
                case Right:
                    ship.waypoint = rotate_vector(ship.waypoint, -command.value);
                    break;
                case Forward:
                    ship.position.x += command.value * ship.waypoint.x;
                    ship.position.y += command.value * ship.waypoint.y;
                    break;
            }
        }
        return {true, abs(ship.position.x) + abs(ship.position.y)};

    }

   private:
    std::vector<Command> parse_input(std::string const& file_name) {
        std::string raw = read_file_raw(file_name);
        StringView sv = {raw};

        std::vector<Command> commands = {};
        while (!sv.empty()) {
            StringView command_raw_sv = sv.chop_by_delim('\n');
            CommandKind command;

            char c = *command_raw_sv.data();
            switch (c) {
                case 'N':
                    command = CommandKind::North;
                    break;
                case 'S':
                    command = CommandKind::South;
                    break;
                case 'E':
                    command = CommandKind::East;
                    break;
                case 'W':
                    command = CommandKind::West;
                    break;
                case 'L':
                    command = CommandKind::Left;
                    break;
                case 'R':
                    command = CommandKind::Right;
                    break;
                case 'F':
                    command = CommandKind::Forward;
                    break;
                default:
                    assert(0 && "Unreachable");
                    break;
            }
            command_raw_sv = command_raw_sv.forward(1);
            std::int32_t value = command_raw_sv.chop_number<std::int32_t>();

            commands.push_back({command, value});
        }
        return commands;
    }
};

class Day12Test : public ::testing::Test {
   protected:
    Day12 problem_{"examples/12.txt"};
};

TEST_F(Day12Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day12Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
