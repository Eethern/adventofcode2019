#include "problem.h"
#include <gtest/gtest.h>
#include <cctype>
#include "string_view.h"

struct XY final
{
    int32_t x;
    int32_t y;
};

// XY offsets
constexpr XY NEIGHBORS[9] = {
    {0, -1}, {0, 0},  {0, 1}, {-1, -1}, {-1, 0},
    {-1, 1}, {1, -1}, {1, 0}, {1, 1},
};

struct Symbol final
{
    XY coord;
    char symbol;
};

struct PartNumber final
{
    std::vector<XY> coords;
    uint64_t value;
};

struct Schematic final
{
    std::vector<PartNumber> parts;
    std::vector<Symbol> symbols;
};

Schematic parse_schematic(std::vector<std::string> const& lines)
{
    Schematic schematic{};

    int32_t row{0};
    for (std::string const& line : lines) {
        StringView line_sv{line.c_str()};

        int32_t column{0};
        while (column < static_cast<int32_t>(line_sv.size())) {
            char c{line_sv[column]};
            if (c == '.') {
                column++;
            } else if (isdigit(c)) {
                uint64_t num{(line_sv.forward(column).chop_u64())};
                PartNumber part{{}, num};
                while (isdigit(c)) {
                    part.coords.push_back({column, row});
                    column++;

                    if (column >= static_cast<int32_t>(line_sv.size()))
                        break;

                    c = line_sv[column];
                }

                schematic.parts.push_back(part);

            } else if (ispunct(c)) {
                Symbol sym{{column, row}, c};
                schematic.symbols.push_back(sym);
                column++;
            } else {
                column++;
            }
        }
        row++;
    }

    return schematic;
}

void print_schematic(Schematic const& schematic)
{
    for (PartNumber const& part : schematic.parts) {
        std::cout << part.value << "\n";
        for (XY const& coord : part.coords) {
            std::cout << coord.x << ',' << coord.y << '\t';
        }
        std::cout << std::endl;
    }

    for (Symbol const& sym : schematic.symbols) {
        std::cout << sym.symbol << ": " << sym.coord.x << ',' << sym.coord.y
                  << "\n";
    }
}

class Day03 : public Problem
{
public:
    Day03(const std::string& input) : Problem(input)
    {
    }
    std::pair<bool, std::uint64_t> part1() override
    {
        std::vector<std::string> lines;
        read_file(input_, lines);
        Schematic const schematic{parse_schematic(lines)};

        uint64_t answer{0U};
        for (PartNumber const& part : schematic.parts) {
            bool is_part{false};
            for (XY const& xy : part.coords) {
                if (is_part)
                    break;
                for (XY const& offset : NEIGHBORS) {
                    if (is_part)
                        break;
                    for (Symbol const& sym : schematic.symbols) {
                        if (is_part)
                            break;
                        if (xy.x + offset.x == sym.coord.x &&
                            xy.y + offset.y == sym.coord.y) {
                            answer += part.value;
                            is_part = true;
                        }
                    }
                }
            }
        }

        return {true, answer};
    }

    std::pair<bool, std::uint64_t> part2() override
    {
        std::vector<std::string> lines;
        read_file(input_, lines);
        Schematic const schematic{parse_schematic(lines)};

        uint64_t answer{0U};
        for (Symbol const& sym : schematic.symbols) {
            size_t num_neighbors{0U};
            uint64_t gear_ratio{1U};
            for (PartNumber const& part : schematic.parts) {
                bool part_counted{false};
                for (XY const& xy : part.coords) {
                    if (part_counted) break;
                    for (XY const& offset : NEIGHBORS) {
                        if (xy.x + offset.x == sym.coord.x &&
                            xy.y + offset.y == sym.coord.y &&
                            sym.symbol == '*') {
                            gear_ratio *= part.value;
                            num_neighbors += 1U;
                            part_counted = true;
                            break;
                        }
                    }
                }
            }

            if (num_neighbors == 2U) {
                answer += gear_ratio;
            }
        }

        return {true, answer};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name)
    {
        (void)file_name;
        return {};
    }
};

class Day03Test : public ::testing::Test
{
protected:
    Day03 problem_{"examples/03.txt"};
    std::string example{
        "467..114.."
        "...*......"
        "..35..633."
        "......#..."
        "617*......"
        ".....+.58."
        "..592....."
        "......755."
        "...$.*...."
        ".664.598.."};
};

TEST_F(Day03Test, part1)
{
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day03Test, part2)
{
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
