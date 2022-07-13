use crate::problem::Problem;
use std::collections::HashMap;
use counter::Counter;

pub struct Solution {}

fn create_rule_map(input: &str) -> HashMap<String, String> {
    input
        .lines()
        .map(|l| l.split_once(" -> ").unwrap())
        .map(|(a, b)| (a.to_string(), b.to_string()))
        .collect::<HashMap<String, String>>()
}

fn parse_input(input: &str) -> (String, HashMap<String, String>) {
    let (template, rules) = input.split_once("\n\n").unwrap();
    (template.to_string(), create_rule_map(rules))
}

fn build_string_solution(template: String, rules: &HashMap<String, String>) -> String {
    let mut new_template = String::new();
    for i in 0..template.len() - 1 {
        new_template.push(template.chars().nth(i).unwrap());
        new_template.push_str(
            rules
                .get(&template[i..i + 2].to_string())
                .unwrap(),
        );
    }
    new_template.push(template.chars().last().unwrap());
    new_template
}

fn count_bigrams_solution(template: String, rules: &HashMap<String, String>, steps: usize) -> Counter<String, u64> {
    let mut letter_counts = Counter::new();
    let mut counts = Counter::new();
    let t_len = template.len();
        
    // Count initial bigrams
    for i in 0..template.len() - 1 {
        letter_counts[&template[i..i+1].to_string()] += 1; 
        counts[
            &template[i..i + 2].to_string()
        ] += 1;
    }

    // Add in missing last character
    letter_counts[&template[t_len-1..t_len].to_string()] += 1;

    // Adjust new bigram counts based on adde characters and existing bigrams
    for _ in 0..steps {
        for (key, n) in counts.clone().iter() {
            if *n > 0 {
                let c = rules.get(key).unwrap();
                counts[&format!("{}{}", key.chars().next().unwrap(), c)] += n;
                counts[&format!("{}{}", c, key.chars().last().unwrap())] += n;
                counts[key] -= n;
                letter_counts[c] += n;
            }
        }
    }
    
    letter_counts
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let (mut template, rules) = parse_input(input);
        for _ in 0..10 {
            template = build_string_solution(template, &rules);
        }

        let counts = template.chars().collect::<Counter<_>>();
        let common = counts.most_common();
        let answer = common[0].1 - common[common.len() - 1].1;

        format!("{}", answer)
    }

    fn part2(&self, input: &str) -> String {
        let (template, rules) = parse_input(input);
        let counts = count_bigrams_solution(template, &rules, 40);
        let common = counts.most_common();
        let answer = common[0].1 - common[common.len() - 1].1;
        format!("{}", answer)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_part1_example() {
        let input = "NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C";

        let (mut template, rules) = parse_input(input);
        template = build_string_solution(template, &rules);
        assert_eq!("NCNBCHB", template); 
        template = build_string_solution(template, &rules);
        assert_eq!("NBCCNBBBCBHCB", template);
        template = build_string_solution(template, &rules);
        assert_eq!("NBBBCNCCNBBNBNBBCHBHHBCHB", template);
        template = build_string_solution(template, &rules);
        assert_eq!("NBBNBNBBCCNBCNCCNBBNBBNBBBNBBNBBCBHCBHHNHCBBCBHCB", template);
    }

    #[test]
    fn test_part2_example() {
        let input = "NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C";

        let (template, rules) = parse_input(input);
        let counts = count_bigrams_solution(template, &rules, 40);
        let common = counts.most_common();
        let answer = common[0].1 - common[common.len() - 1].1;
        assert_eq!(answer, 2188189693529);
        
    }
}
