#include "problem.h"
#include "string_view.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <limits>
#include <string>

struct Pull
{
    uint32_t red;
    uint32_t blue;
    uint32_t green;
};

struct Game
{
    uint32_t id;
    std::vector<Pull> pulls;
};

class Day02 : public Problem
{
public:
    Day02(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        std::vector<std::string> lines;
        this->read_file(this->input_, lines);

        std::vector<Game> games{};

        for (std::string const& line : lines)
        {
            Game game{parse_game(line)};
            games.push_back(game);
        }

        uint32_t max_red{12U};
        uint32_t max_green{13U};
        uint32_t max_blue{14U};

        uint32_t answer{0U};
        for (Game const& game : games) {
            bool valid_game{true};
            for (Pull const& pull : game.pulls) {
                if (pull.red > max_red || pull.green > max_green || pull.blue > max_blue) {
                    valid_game = false;
                    break;
                }
            }
            if (valid_game) {
                answer += game.id;
            }
        }

        return {true, static_cast<uint64_t>(answer)};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        std::vector<std::string> lines;
        this->read_file(this->input_, lines);

        std::vector<Game> games{};

        for (std::string const& line : lines)
        {
            Game game{parse_game(line)};
            games.push_back(game);
        }

        uint32_t answer{0U};
        for (Game const& game : games) {
            uint32_t fewest_red{std::numeric_limits<uint32_t>().min()};
            uint32_t fewest_blue{std::numeric_limits<uint32_t>().min()};
            uint32_t fewest_green{std::numeric_limits<uint32_t>().min()};

            for (Pull const& pull : game.pulls) {
                fewest_red = std::max<uint32_t>(fewest_red, pull.red);
                fewest_blue = std::max<uint32_t>(fewest_blue, pull.blue);
                fewest_green = std::max<uint32_t>(fewest_green, pull.green);
            }

            uint32_t power_set{fewest_red * fewest_blue * fewest_green};
            answer += power_set;
        }

        return {true, static_cast<uint64_t>(answer)};
    }

private:
    Game parse_game(std::string const& game_raw)
    {
        StringView sv{game_raw.c_str()};
        sv.chop_by_delim(' ');

        Game game = {};
        game.id = std::stoi(sv.chop_by_delim(' ').to_string());

        while (sv.size() > 0U) {
            Pull pull{};
            StringView sv_pull{sv.chop_by_delim(';')};
            sv_pull = sv_pull.trim_left();

            while (sv_pull.size() > 0U) {
                uint32_t num = std::stoi(sv_pull.chop_by_delim(' ').to_string());
                std::string color = sv_pull.chop_by_sv({", "}).to_string();

                if (color == "blue") {
                    pull.blue = num;
                } else if (color == "red") {
                    pull.red = num;
                } else if (color == "green") {
                    pull.green = num;
                } else {
                    std::cerr << "Unknown color: " << color << std::endl;
                }
            }

            game.pulls.push_back(pull);

        }

        return game;
    }
};

class Day02Test : public ::testing::Test
{
protected:
    Day02 problem_{"examples/Day02.txt"};
};

TEST_F(Day02Test, part1)
{
    std::pair<bool, std::uint32_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day02Test, part2)
{
    std::pair<bool, std::uint32_t> result{problem_.part2()};
    (void)result;
}
