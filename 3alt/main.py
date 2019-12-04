import sys


# Moves along wire, counting steps and storing positions
def traverse_wire(wire):
    # Dictionary to store wire informatiosn
    wire_dist = {}
    # Dictionary to keep track of directions
    directions = {'R': [1, 0], 'L': [-1, 0], 'U': [0, 1], 'D': [0, -1]}
    x, y, stepCount = 0, 0, 0
    for vec in wire:
        for _ in range(int(vec[1:])):
            direction = directions[vec[0]]
            x += direction[0]
            y += direction[1]
            stepCount += 1
            wire_dist[(x, y)] = stepCount
    return wire_dist


def solver(wire1, wire2):
    # Traverse wires
    wire_one = traverse_wire(wire1)
    wire_two = traverse_wire(wire2)

    # Calculate crossings
    crossings = wire_one.keys() & wire_two.keys()

    fewest_steps = min(crossings, key=lambda x: wire_one[x] + wire_two[x])
    steps = wire_one[fewest_steps] + wire_two[fewest_steps]

    closest = min([intersection for intersection in crossings],
                  key=lambda x: abs(x[0]) + abs(x[1]))

    # Manhattan distance
    distance = abs(closest[0]) + abs(closest[1])

    return ('task 1', distance, 'task 2', steps)


def main():
    # Open file
    f = open(sys.argv[1], 'r')
    raw_data = f.read().rstrip().split('\n')
    f.close()

    raw_wire1 = raw_data[0].split(',')
    raw_wire2 = raw_data[1].split(',')

    solver(raw_wire1, raw_wire2)
    print(solver(raw_wire1, raw_wire2))


if (__name__ == '__main__'):
    main()
