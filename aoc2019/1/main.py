import sys
import math


def massToFuel(mass):
    return math.floor(float(mass) / 3) - 2


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
