use crate::problem::Problem;

pub struct Template {}

impl Problem for Template {
    fn part1(&self, input: &str) -> String {
        format!("{}", "undefined")
    }

    fn part2(&self, input: &str) -> String {
        format!("{}", "undefined")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
