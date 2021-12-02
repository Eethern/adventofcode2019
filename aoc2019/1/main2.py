import sys
import math


def massToFuel(mass):
    fuel = math.floor(float(mass) / 3) - 2
    if (fuel <= 0):
        return 0
    return fuel + massToFuel(fuel)


def calcTotalFuel(masses):
    masses = map(massToFuel, masses.split())
    return sum(masses)


def main():
    path = sys.argv[1]
    f = open(path, 'r')
    total = calcTotalFuel(f.read())
    f.close()

    print(total)


if (__name__ == '__main__'):
    main()
