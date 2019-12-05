import sys
from enum import Enum


class Opcodes(Enum):
    ADD = '01'
    MUL = '02'
    INP = '03'
    OUT = '04'
    HALT = '99'


class Modes(Enum):
    ADDR = '0'
    IM = '1'


def parseOperation(opcode):
    # Extend trailin zeroes
    parse = opcode
    for _ in range(5 - len(opcode)):
        parse = '0' + parse

    # Read chars from right to left
    op = Opcodes(parse[-2:])
    parse = parse[:-2]
    parse = parse[::-1]
    modes = [Modes(x) for x in parse]

    print(op, modes)
    return (op, modes)


def parseMode(mode, val, mem):
    if mode is Modes.ADDR:
        return int(mem[int(val)])
    else:
        return int(val)


def executeOperation(inputVal, mem, memPointer, opInfo):
    # Get op and modes
    op = opInfo[0]
    modes = opInfo[1]

    if (op is Opcodes.ADD):
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        dest = mem[memPointer + 3]
        mem[int(dest)] = str(param1 + param2)
        incrPointer = 4

    elif (op is Opcodes.MUL):
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        dest = mem[memPointer + 3]
        mem[int(dest)] = str(param1 * param2)
        incrPointer = 4

    elif (op is Opcodes.INP):
        param1 = mem[memPointer + 1]
        mem[int(param1)] = inputVal
        incrPointer = 2

    elif (op is Opcodes.OUT):
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        print(param1)
        incrPointer = 2
    else:
        print("Op HALT = '99', exiting")
        incrPointer = 1
    return incrPointer


def executeIntCode(mem, inputVal):
    instrPointer = 0

    while(instrPointer < len(mem)):
        opInfo = parseOperation(mem[instrPointer])
        instrPointer += executeOperation(inputVal, mem, instrPointer, opInfo)


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

    mem = list(raw_data.rstrip().split(','))
    executeIntCode(mem, '1')


if (__name__ == '__main__'):
    main()
