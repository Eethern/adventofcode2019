import sys
from enum import Enum
import time


class Opcodes(Enum):
    ADD = '01'  # Add
    MUL = '02'  # Multiply
    INP = '03'  # Input
    OUT = '04'  # Output
    JIT = '05'  # Jump if true
    JIF = '06'  # Jump if false
    SLE = '07'  # Store less than
    SEQ = '08'  # store equal
    HALT = '99'  # exit


class Modes(Enum):
    ADDR = '0'
    IM = '1'


def parseOperation(opcode):
    # Extend trailin zeroes
    parse = opcode
    for _ in range(5 - len(opcode)):
        parse = '0' + parse

    # Read chars from right to left
    print(parse)
    op = Opcodes(parse[-2:])
    parse = parse[:-2]
    parse = parse[::-1]
    modes = [Modes(x) for x in parse]

    print(op, modes)
    return (op, modes)


def parseMode(mode, val, mem):
    # print(mode, val)
    if mode is Modes.ADDR:
        # print(int(mem[int(val)]))
        return int(mem[int(val)])
    else:
        return int(val)


def executeOperation(inputVal, mem, memPointer, opInfo):
    # Get op and modes
    op = opInfo[0]
    modes = opInfo[1]
    # print(mem[memPointer:40])

    if op is Opcodes.ADD:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        dest = int(mem[memPointer + 3])
        print(param1,param2,dest)
        mem[dest] = str(param1 + param2)
        return 4

    elif op is Opcodes.MUL:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        dest = int(mem[memPointer + 3])
        mem[dest] = str(param1 * param2)
        return 4

    elif op is Opcodes.INP:
        dest = mem[memPointer + 1]
        print(dest)
        mem[int(dest)] = inputVal
        return 2

    elif op is Opcodes.OUT:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        print(param1)
        return 2

    elif op is Opcodes.JIT:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        print(param1,param2)
        if (param1) != 0:
            return param2 - memPointer
        else:
            return 3

    elif op is Opcodes.JIF:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        if param1 == 0:
            return param2 - memPointer
        else:
            return 3

    elif op is Opcodes.SLE:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        dest = int(mem[memPointer + 3])
        if param1 < param2:
            mem[dest] = str(1)
        else:
            mem[dest] = str(0)
        return 4

    elif op is Opcodes.SEQ:
        param1 = parseMode(modes[0], mem[memPointer + 1], mem)
        param2 = parseMode(modes[1], mem[memPointer + 2], mem)
        dest = int(mem[memPointer + 3])
        print(dest)
        if param1 == param2:
            mem[dest] = str(1)
        else:
            mem[dest] = str(0)
        return 4
    else:
        print("Op HALT = '99', exiting")
        return 1


def executeIntCode(mem, inputVal):
    instrPointer = 0

    while(instrPointer < len(mem)):
        opInfo = parseOperation(mem[instrPointer])
        instrPointer += executeOperation(inputVal, mem, instrPointer, opInfo)
        time.sleep(0.1)


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

    mem = list(raw_data.rstrip().split(','))
    executeIntCode(mem, '5')


if (__name__ == '__main__'):
    main()
