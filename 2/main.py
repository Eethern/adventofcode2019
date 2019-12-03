import sys


def executeIntCode(arr):
    intCode = arr
    cur = 0

    while(cur <= len(intCode)):
        if (intCode[cur] == 99):
            return intCode
        elif (intCode[cur] == 1):
            intCode[intCode[cur + 3]] = intCode[intCode[cur + 1]] + intCode[intCode[cur + 2]]

        elif (intCode[cur] == 2):
            intCode[intCode[cur + 3]] = intCode[intCode[cur + 1]] * intCode[intCode[cur + 2]]

        cur += 4

    return intCode


def main():
    path = sys.argv[1]
    f = open(path, 'r')
    intCodeArr = list(map(int, f.read().rstrip().split(',')))
    f.close()

    resultArr = executeIntCode(intCodeArr)

    print(resultArr)


if (__name__ == '__main__'):
    main()
