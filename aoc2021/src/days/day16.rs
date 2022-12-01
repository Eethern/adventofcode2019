use crate::problem::Problem;

pub struct Solution {}

#[derive(Clone, Debug)]
enum Packet {
    Op(Operator),
    Lit(Literal),
}

#[derive(Clone, Debug)]
struct Header {
    version: u64,
    type_id: u64,
}

#[derive(Clone, Debug)]
struct Literal {
    header: Header,
    value: u64,
    size: usize,
}

#[derive(Clone, Debug)]
struct Operator {
    header: Header,
    children: Vec<Packet>,
    size: usize,
}

fn cast_to_u64(bits: &[u8]) -> u64 {
    bits.iter()
        .enumerate()
        .fold(0, |acc, (_, &b)| acc * 2 + (b as u64))
}

fn parse(message: &str) -> Packet {
    parse_packet(&parse_message(message))
}

fn parse_header(bits: &[u8]) -> Header {
    Header {
        version: cast_to_u64(&bits[0..3]),
        type_id: cast_to_u64(&bits[3..6]),
    }
}

fn parse_packet(bits: &[u8]) -> Packet {
    match cast_to_u64(&bits[3..6]) {
        4 => parse_literal(bits),
        _ => parse_operator(bits),
    }
}

fn parse_literal(bits: &[u8]) -> Packet {
    let mut value = vec![];
    let mut index = 0;
    let data = &bits[6..];

    while index <= data.len() - 5 {
        let chunk = &data[index..index + 5];
        let cont = chunk[0];
        value.extend(&chunk[1..5]);

        index += 5;

        if cont == 0 {
            break;
        }
    }

    Packet::Lit(Literal {
        header: parse_header(bits),
        value: cast_to_u64(&value),
        size: 6 + index,
    })
}

fn parse_operator(bits: &[u8]) -> Packet {
    let length_type_id = bits[6];
    let offset = 7 + if length_type_id == 0 { 15 } else { 11 };
    let size = cast_to_u64(&bits[7..offset]) as usize;

    let mut index = 0;
    let mut children = vec![];
    while (length_type_id == 0 && index < size) || (length_type_id == 1 && children.len() < size) {
        let packet = parse_packet(&bits[(offset + index)..]);
        index += match &packet {
            Packet::Lit(data) => data.size,
            Packet::Op(data) => data.size,
        };

        children.push(packet);
    }

    Packet::Op(Operator {
        header: parse_header(bits),
        children,
        size: offset + index,
    })
}

fn parse_message(message: &str) -> Vec<u8> {
    message
        .lines()
        .next()
        .unwrap()
        .chars()
        .flat_map(|c| match c {
            '0' => [0, 0, 0, 0],
            '1' => [0, 0, 0, 1],
            '2' => [0, 0, 1, 0],
            '3' => [0, 0, 1, 1],
            '4' => [0, 1, 0, 0],
            '5' => [0, 1, 0, 1],
            '6' => [0, 1, 1, 0],
            '7' => [0, 1, 1, 1],
            '8' => [1, 0, 0, 0],
            '9' => [1, 0, 0, 1],
            'A' => [1, 0, 1, 0],
            'B' => [1, 0, 1, 1],
            'C' => [1, 1, 0, 0],
            'D' => [1, 1, 0, 1],
            'E' => [1, 1, 1, 0],
            'F' => [1, 1, 1, 1],
            c => panic!("expected hex character, found {}", c),
        })
        .collect::<Vec<u8>>()
}

fn add_version_numbers(packet: &Packet) -> u64 {
    match packet {
        Packet::Lit(data) => data.header.version,
        Packet::Op(data) => data
            .children
            .iter()
            .fold(data.header.version, |acc, p| acc + add_version_numbers(p)),
    }
}

fn evaluate(packet: &Packet) -> u64 {
    match packet {
        Packet::Lit(data) => data.value,
        Packet::Op(data) => {
            let values: Vec<u64> = data
                .children
                .iter()
                .map(|child| match child {
                    Packet::Lit(c_data) => c_data.value,
                    Packet::Op(c_data) => evaluate(&Packet::Op(c_data.clone())),
                })
                .collect();

            match data.header.type_id {
                0 => values.iter().sum(),
                1 => values.iter().product(),
                2 => *values.iter().min().unwrap(),
                3 => *values.iter().max().unwrap(),
                5 => {
                    if values[0] > values[1] {
                        1
                    } else {
                        0
                    }
                }
                6 => {
                    if values[0] < values[1] {
                        1
                    } else {
                        0
                    }
                }
                7 => {
                    if values[0] == values[1] {
                        1
                    } else {
                        0
                    }
                }
                c => panic!("encounterd unknown operation: {}", c),
            }
        }
    }
}

impl Problem for Solution {
    fn part1(&self, input: &str) -> String {
        let packet = parse(input);
        let answer = add_version_numbers(&packet);
        format!("{}", answer)
    }

    fn part2(&self, input: &str) -> String {
        let packet = parse(input);
        let answer = evaluate(&packet);
        format!("{}", answer)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hex_to_bin() {
        assert_eq!(parse_message("ABC\n"), [1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0]);
    }

    #[test]
    fn test_cast_to_u64() {
        assert_eq!(cast_to_u64(&[0, 1, 0, 0]), 4);
        assert_eq!(cast_to_u64(&[0, 0, 0, 1, 0, 1]), 5);
    }

    #[test]
    fn test_part1_operator_packet_v4() {
        let input = "8A004A801A8002F478";
        let packet = parse(input);
        assert_eq!(16, add_version_numbers(&packet));
    }

    #[test]
    fn test_part1_operator_packet_v3() {
        let input = "620080001611562C8802118E34";
        let packet = parse(input);
        assert_eq!(12, add_version_numbers(&packet));
    }

    #[test]
    fn test_part1_operator_packet_length_type() {
        let input = "C0015000016115A2E0802F182340";
        let packet = parse(input);
        assert_eq!(23, add_version_numbers(&packet));
    }

    #[test]
    fn test_part1_operator_packet_nested() {
        let input = "A0016C880162017C3686B18A3D4780";
        let packet = parse(input);
        assert_eq!(31, add_version_numbers(&packet));
    }

    #[test]
    fn test_part2_add() {
        assert_eq!(3, evaluate(&parse("C200B40A82")), "Testing add: 1+2");
        assert_eq!(54, evaluate(&parse("04005AC33890")), "Testing mul: 6*9");
        assert_eq!(
            7,
            evaluate(&parse("880086C3E88112")),
            "Testing min: min(7,8,9)"
        );
        assert_eq!(
            9,
            evaluate(&parse("CE00C43D881120")),
            "Testing max: max(7,8,9)"
        );
        assert_eq!(1, evaluate(&parse("D8005AC2A8F0")), "Testing lt: 5<15");
        assert_eq!(0, evaluate(&parse("F600BC2D8F")), "Testing gt: 5>15");
        assert_eq!(0, evaluate(&parse("9C005AC2F8F0")), "Testing eq: 5==15");
        assert_eq!(
            1,
            evaluate(&parse("9C0141080250320F1802104A08")),
            "Testing all: 1*3==2*2"
        );
    }
}
