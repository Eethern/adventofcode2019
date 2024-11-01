#include <gtest/gtest.h>
#include <algorithm>
#include <deque>
#include <string>
#include <unordered_map>
#include "problem.h"

#include "string_view.h"

typedef struct {
  std::string dest;
  std::uint64_t weight;
} Edge;

typedef struct {
  std::string color;
  std::vector<Edge> adj_list;
} Node;

typedef std::unordered_map<std::string, std::vector<Edge>> BagGraph;

class Day07 : public Problem {
 public:
  Day07(const std::string& input) : Problem(input) {}
  std::pair<bool, std::uint64_t> part1() override {
    BagGraph graph = parse_input(input_);
    BagGraph rev_graph = build_reverse_graph(graph);

    std::vector<std::string> outer_bags =
        find_outer_bags(rev_graph, "shiny gold");

    return {true, outer_bags.size() - 1};
  }

  std::pair<bool, std::uint64_t> part2() override {
    BagGraph graph = parse_input(input_);
    std::uint64_t num_bags = count_bags(graph, "shiny gold");
    return {true, num_bags - 1};
  }

 private:
  BagGraph parse_input(std::string const& file_name) {
    std::vector<std::string> lines;
    read_file(file_name, lines);

    BagGraph graph = {};
    for (std::string& line : lines) {
      StringView sv{line.c_str()};
      StringView base_color{sv.chop_by_sv({" bags contain "})};

      std::vector<Edge> edges = {};

      while (!sv.empty()) {
        std::uint64_t amount = sv.chop_number<std::uint64_t>();
        if (amount == 0) {
          break;
        }
        sv.trim_left();

        StringView color = sv.chop_by_sv({" bag"});
        sv.chop_by_delim(' ');

        Edge edge = {color.trim_left().to_string(), amount};
        edges.push_back(edge);
      }
      graph.insert({base_color.to_string(), edges});
    }

    return graph;
  }

  void print_bag_graph(BagGraph const& graph) {
    for (auto const& it : graph) {
      std::cout << it.first << ':' << std::endl;
      for (auto const& edge : it.second) {
        std::cout << '\t' << unsigned(edge.weight) << ' ' << edge.dest
                  << std::endl;
      }
      std::cout << std::endl;
    }
  }

  BagGraph build_reverse_graph(BagGraph const& graph) {
    BagGraph rev_graph = {};
    for (auto it : graph) {
      std::string src = it.first;
      std::vector<Edge> edges = it.second;

      if (!rev_graph.count(src)) {
        rev_graph.insert({src, {}});
      }

      for (Edge const& edge : edges) {
        std::string dest = edge.dest;

        if (!rev_graph.count(dest)) {
          rev_graph.insert({dest, {}});
        }

        rev_graph.at(dest).push_back({src, edge.weight});
      }
    }
    return rev_graph;
  }

  std::vector<std::string> find_outer_bags(BagGraph const& rev_graph,
                                           std::string const& start_name) {
    std::deque<std::string> to_visit = {start_name};
    std::set<std::string> visited = {};
    while (!to_visit.empty()) {
      std::string const next = to_visit.at(0);
      to_visit.pop_front();
      visited.insert(next);

      std::vector<Edge> const& edges = rev_graph.at(next);
      for (Edge const& edge : edges) {
        if (!visited.count(edge.dest)) {
          to_visit.push_back(edge.dest);
        }
      }
    }
    return std::vector<std::string>(visited.begin(), visited.end());
  }

  std::uint64_t count_bags(BagGraph const& graph,
                           std::string const& start_name) {
    std::deque<Edge> to_visit = {{start_name, 1}};
    std::set<std::string> visited = {};
    std::uint64_t num_bags = 0U;
    while (!to_visit.empty()) {
      Edge const next = to_visit.at(0);
      to_visit.pop_front();
      num_bags += next.weight;

      std::vector<Edge> const& edges = graph.at(next.dest);
      for (Edge const& edge : edges) {
        to_visit.push_back({edge.dest, next.weight * edge.weight});
      }
    }
    return num_bags;
  }
};

class Day07Test : public ::testing::Test {
 protected:
  Day07 problem_{"examples/07.txt"};
};

TEST_F(Day07Test, part1) {
  std::pair<bool, std::uint64_t> result{problem_.part1()};
  (void)result;
}

TEST_F(Day07Test, part2) {
  std::pair<bool, std::uint64_t> result{problem_.part2()};
  (void)result;
}
