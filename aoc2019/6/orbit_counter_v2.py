class Planet:
    def __init__(self, name):
        # Keep track of children
        self.name = name
        # Empty parent
        self.parent = ""


def calculateUniverse(orbits):
    # Store Planets in a dict
    universe = {}

    # Add all planets
    for orbit in orbits:
        parent = orbit[0]
        child = orbit[1]
        for planet in orbit:
            if planet not in universe:
                # Add planet to universe
                universe[planet] = Planet(planet)

        # Add edge from parent planet to child planet
        universe[child].parent = universe[parent]

    return universe


def verifyOrbits(universe):
    # For every planet, count your steps, moving up the tree until you reach
    # COM
    steps = 0
    for planet in universe.values():
        steps += len(planetsToCOM(universe, planet))

    return steps


def planetsToCOM(universe, start):
    parents = []
    currentPlanet = start
    while currentPlanet is not universe['COM']:
        currentPlanet = currentPlanet.parent
        parents.append(currentPlanet)

    return parents


def calcOrbitTransfers(universe, start, end):
    # Traverse up tree to COM from start and from end
    startParents = planetsToCOM(universe, start)
    endParents = planetsToCOM(universe, end)

    intersect = (list(set(startParents).intersection(endParents)))

    # Number of transfers is length of both - 2 * intersection length + 2 for
    # the common node in path (exit and enter counts as 2 transfers)
    return len(startParents) + len(endParents) - 2 * len(intersect) + 2


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

    orbits = list(raw_data.rstrip().split('\n'))
    orbits = [orbit.split(')') for orbit in orbits]

    universe = calculateUniverse(orbits)

    steps = verifyOrbits(universe)
    transfers = calcOrbitTransfers(universe, universe['YOU'].parent, universe['SAN'].parent)
    print("#of direct and indirect orbits: {val}".format(val=steps))
    print("#of transfer from YOU to SAN: {val}".format(val=transfers))


if (__name__ == '__main__'):
    main()
