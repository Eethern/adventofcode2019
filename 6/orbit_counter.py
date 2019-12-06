from anytree import Node, RenderTree
from anytree.exporter import DotExporter
from anytree.walker import Walker


def printTree(tree):
    for pre, fill, node in RenderTree(tree['COM']):
        print("%s%s" % (pre, node.name))

def verifyOrbits(orbits):
    # Store Planets in a dict
    Planets = {}

    # Add all planets
    for orbit in orbits:
        parent = orbit[0]
        child = orbit[1]
        for planet in orbit:
            if planet not in Planets:
                # Add planet to Planets
                Planets[planet] = Node(planet)

        # Add edge from parent planet to child planet

        Planets[child].parent = Planets[parent]

    # For every planet, count your steps, moving up the tree until you reach
    # COM
    steps = 0
    for planet in Planets.values():
        currentPlanet = planet
        while currentPlanet is not Planets['COM']:
            steps += 1
            currentPlanet = currentPlanet.parent

    return (steps, Planets)


def calculateOrbitTransfers(orbits, start, end):
    w = Walker()
    path = w.walk(start, end)
    return len(path[0]) + len(path[2])


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

    orbits = list(raw_data.rstrip().split('\n'))
    orbits = [orbit.split(')') for orbit in orbits]

    (result, Planets) = verifyOrbits(orbits)
    transfers = calculateOrbitTransfers(Planets, Planets['YOU'].parent, Planets['SAN'].parent)
    print("#of direct and indirect orbits: {val}".format(val=result))
    print("#of transfer from YOU to SAN: {val}".format(val=transfers))


if (__name__ == '__main__'):
    main()
