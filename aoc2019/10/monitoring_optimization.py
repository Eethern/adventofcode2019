from math import gcd


def vecToTarget(observerPos, targetPos):
    x = targetPos[0] - observerPos[0]
    y = targetPos[1] - observerPos[1]

    # Calculate GCD
    if (x == 0 and y == 0):
        gcdVal = 1
    else:
        gcdVal = gcd(abs(x), abs(y))

    return (x / gcdVal, y / gcdVal)


def testAsteroid(asteroid, asteroids):
    # Copy to ensure immutability
    copy = asteroids.copy()
    # Store vectors in dict
    vectors = {}
    # Calculate rays to all other asteroids
    for target in copy:
        vectors[vecToTarget(asteroid, target)] = True

    # Visible is number of keys in dict - 1 for observer
    return len(vectors.keys()) - 1


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

        coords = list(raw_data.rstrip().split('\n'))
        height = len(coords)
        width = len(coords[0])

        # Get list of all asteroid positions
        asteroids = []
        # Store visible asteroids values in dict
        visible = {}

        # Find all asteroids
        for y in range(height):
            for x in range(width):
                if coords[y][x] == '#':
                    asteroids.append((x, y))

        # Test all asteroids
        for asteroid in asteroids:
            # Test asteroid
            vis = testAsteroid(asteroid, asteroids)
            visible[asteroid] = vis

        bestLocation = max(visible, key=visible.get)
        maxVisible = visible[bestLocation]

        print("Max visible at {asteroid} with {vis} visible asteroids".format(asteroid=bestLocation, vis=maxVisible))


if (__name__ == '__main__'):
    main()
