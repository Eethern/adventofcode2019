import sys


def executeIntCode(mem):
    intCode = mem.copy()
    instr_p = 0
    maxLength = len(intCode)

    while(instr_p < maxLength):
        op = intCode[instr_p]
        param1 = intCode[instr_p + 1]
        param2 = intCode[instr_p + 2]
        dest = intCode[instr_p + 3]

        if (op == 99):
            return intCode
        elif (op == 1):
            intCode[dest] = intCode[param1] + intCode[param2]
        elif (op == 2):
            intCode[dest] = intCode[param1] * intCode[param2]

        instr_p += 4
    return intCode


def bruteForce(maxNoun, maxVerb, mem, desiredVal):
    for noun in range(maxNoun + 1):
        for verb in range(maxVerb + 1):
            arr = mem.copy()
            arr[1] = noun
            arr[2] = verb
            result = executeIntCode(arr)
            if (result[0] == desiredVal):
                return (noun, verb)


def calculateAnswer(noun, verb):
    return 100 * noun + verb

def main():
    path = sys.argv[1]
    f = open(path, 'r')
    intCodeArr = list(map(int, f.read().rstrip().split(',')))
    f.close()
    (noun, verb) = bruteForce(99, 99, intCodeArr, 19690720)
    print(calculateAnswer(noun, verb))


if (__name__ == '__main__'):
    main()
