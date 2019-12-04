with open(r'input.txt', 'r') as f:
    raw_input = f.read()


def traverse_wire(wire):
    # Dictionary to store wire informatiosn
    wire_dist = {}
    # Dictionary to keep track of directions
    directions = {'R': [1, 0], 'L': [-1, 0], 'U': [0, 1], 'D': [0, -1]}
    x, y, stepCount = 0, 0, 0
    for vec in wire:
        for _ in range(int(vec[1:])):
            dir = directions[vec[0]]
            x += dir[0]
            y += dir[1]
            stepCount += 1
            wire_dist[(x, y)] = stepCount
    return wire_dist


def solutions(raw_input):
    wires = [x.split(',') for x in raw_input.strip().split('\n')]

    wire_one = traverse_wire(wires[0])
    wire_two = traverse_wire(wires[1])

    crossings = wire_one.keys() & wire_two.keys()

    fewest_steps = min(crossings, key=lambda x: wire_one[x] + wire_two[x])
    steps = wire_one[fewest_steps] + wire_two[fewest_steps]

    closest = min([intersection for intersection in crossings], key=lambda x: abs(x[0]) + abs(x[1]))
    distance = abs(closest[0]) + abs(closest[1])

    return ('task 1', distance, 'task 2', steps)


print(solutions(raw_input))
