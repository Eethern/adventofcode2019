#include <gtest/gtest.h>

#include <algorithm>
#include <cstdint>

#include "problem.h"
#include "string_view.h"

#define MAX_STEPS 1000000

struct Node {
    uint32_t id;
    char ending_char;
    uint32_t left;
    uint32_t right;
};

enum Dir { RIGHT = 0, LEFT = 1 };

struct Map {
    std::vector<Dir> directions;
    std::map<uint32_t, Node> adj;
};

uint32_t encode_node_name(StringView const& name_sv) {
    uint32_t hash = 2166136261u;  // FNV-1a initial value

    for (char c : name_sv) {
        hash ^= static_cast<uint32_t>(c);
        hash *= 16777619u;  // FNV-1a prime number
    }

    return hash;
}

Node parse_node(StringView& sv) {
    StringView name_sv{sv.chop_by_delim(' ')};
    uint32_t id = encode_node_name(name_sv);
    char ending_char{name_sv[name_sv.size() - 1U]};

    sv.chop_by_delim('(');
    uint32_t left = encode_node_name(sv.chop_by_delim(','));
    sv.trim_left_mut();
    uint32_t right = encode_node_name(sv.chop_by_delim(')'));

    return {id, ending_char, left, right};
}

void print_node(Node const& n) {
    std::cout << "id: " << n.id << "\tleft: " << n.left
              << "\tright: " << n.right << "\n";
}

std::map<uint32_t, Node> parse_adj(StringView& sv) {
    std::map<uint32_t, Node> node_map{};
    while (sv.size() > 0U) {
        Node n{parse_node(sv)};
        sv.chop_by_delim('\n');

        // print_node(n);
        node_map[n.id] = n;
    }

    return node_map;
}

std::vector<Dir> parse_steps(StringView const& sv) {
    std::vector<Dir> out{};
    for (char c : sv) {
        if (c == 'R') {
            out.push_back(Dir::RIGHT);
        } else if (c == 'L') {
            out.push_back(Dir::LEFT);
        } else {
            std::cerr << "Invalid direction encountered: " << c << std::endl;
            exit(1);
        }
    }
    return out;
}

Map parse_map(StringView& raw_sv) {
    Map map{};
    StringView steps_sv = raw_sv.chop_by_delim('\n');
    map.directions = parse_steps(steps_sv);

    raw_sv.chop_by_delim('\n');
    map.adj = parse_adj(raw_sv);

    return map;
}

struct LoopCounter {
    uint32_t start_node_id;
    Dir dir;
    uint32_t start_step;
    uint32_t end_step;
    bool finished;
};

struct Ghost {
    uint32_t current_node_id;
    std::vector<LoopCounter> z_stack;
    bool inside_loop;
};

uint32_t gcd(uint64_t x, uint64_t y) {
    while (y != 0U) {
        x = y;
        y = x % y;
    }
    return x;
}

class Day08 : public Problem {
public:
    Day08(const std::string& input) : Problem(input) {
    }
    std::pair<bool, std::uint64_t> part1() override {
        // parse
        std::string file_content{};
        if (!read_file_raw(input_, file_content)) {
            return {false, NULL};
        }
        StringView raw_sv{file_content};

        Map map{parse_map(raw_sv)};

        // solve
        uint32_t start{encode_node_name({"AAA"})};
        uint32_t end{encode_node_name({"ZZZ"})};

        uint32_t current{start};

        uint64_t num_steps{0U};
        while (num_steps < MAX_STEPS) {
            Dir d{map.directions[num_steps % map.directions.size()]};

            if (current == end) {
                break;
            }

            switch (d) {
                case Dir::RIGHT:
                    current = map.adj[current].right;
                    break;
                case Dir::LEFT:
                    current = map.adj[current].left;
                    break;
                default:
                    std::cerr << "Unknown direction encountered: " << d
                              << std::endl;
                    exit(1);
            }

            num_steps++;
        }

        return {true, num_steps};
    }

    std::pair<bool, std::uint64_t> part2() override {
        // parse
        std::string file_content{};
        if (!read_file_raw(input_, file_content)) {
            return {false, NULL};
        }
        StringView raw_sv{file_content};

        Map map{parse_map(raw_sv)};

        // solve
        std::vector<Ghost> ghosts{};
        for (const auto& kv : map.adj) {
            if (kv.second.ending_char == 'A') {
                Ghost ghost{kv.second.id, {}, false};

                ghosts.push_back(ghost);
            }
        }

        uint32_t num_steps{0U};
        bool all_ghosts_in_loop{false};
        while (!all_ghosts_in_loop) {
            Dir d{map.directions[num_steps % map.directions.size()]};
            all_ghosts_in_loop = true;

            for (Ghost& ghost : ghosts) {
                Node const& current = map.adj[ghost.current_node_id];

                if (ghost.inside_loop) {
                    continue;
                } else {
                    all_ghosts_in_loop = false;
                }

                if (current.ending_char == 'Z') {
                    bool seen_before{false};
                    for (LoopCounter& lc : ghost.z_stack) {
                        if (lc.start_node_id == current.id && lc.dir == d) {
                            seen_before = true;
                            lc.finished = true;
                            lc.end_step = num_steps;
                            ghost.inside_loop = true;
                            break;
                        }
                    }

                    if (!seen_before) {
                        ghost.z_stack.push_back(
                            {current.id, d, num_steps, 0U, false});
                    }
                }

                switch (d) {
                    case Dir::RIGHT:
                        ghost.current_node_id = current.right;
                        break;
                    case Dir::LEFT:
                        ghost.current_node_id = current.left;
                        break;
                    default:
                        std::cerr << "Unknown direction encountered: " << d
                                  << std::endl;
                        exit(1);
                }
            }

            num_steps++;
        }

        uint64_t largest_loop_size{0U};
        for (Ghost const& ghost : ghosts) {
            for (LoopCounter const& lc : ghost.z_stack) {
                uint32_t loop_size{lc.end_step - lc.start_step};
                largest_loop_size =
                    std::max<uint64_t>(largest_loop_size, loop_size);
            }
        }

        uint64_t step;
        for (step = largest_loop_size; true; step += largest_loop_size) {
            bool are_same{true};
            for (Ghost const& ghost : ghosts) {
                for (LoopCounter const& lc : ghost.z_stack) {
                    uint32_t loop_size{lc.end_step - lc.start_step};
                    are_same &= step % loop_size == 0U;
                }
            }
            if (are_same)
                break;
        }

        return {true, step};
    }

private:
    std::vector<uint32_t> parse_input(std::string const& file_name) {
        (void)file_name;
        return {};
    }
};

class Day08Test : public ::testing::Test {
protected:
    Day08 problem_{"examples/08.txt"};
};

TEST_F(Day08Test, part1) {
    std::pair<bool, std::uint64_t> result{problem_.part1()};
    (void)result;
}

TEST_F(Day08Test, part2) {
    std::pair<bool, std::uint64_t> result{problem_.part2()};
    (void)result;
}
