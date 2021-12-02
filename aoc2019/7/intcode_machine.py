from enum import Enum
import time

class Opcodes(Enum):
    ADD = 1  # Add
    MUL = 2  # Multiply
    INP = 3  # Input
    OUT = 4  # Output
    JIT = 5  # Jump if true
    JIF = 6  # Jump if false
    SLE = 7  # Store less than
    SEQ = 8  # store equal
    HALT = 99  # exit


# Operation, Parameter count
def opInfo():
    return {
        1: (Opcodes.ADD, 3),
        2: (Opcodes.MUL, 3),
        3: (Opcodes.INP, 1),
        4: (Opcodes.OUT, 1),
        5: (Opcodes.JIT, 2),
        6: (Opcodes.JIF, 2),
        7: (Opcodes.SLE, 3),
        8: (Opcodes.SEQ, 3),
        99: (Opcodes.HALT, 0)
    }


class Modes(Enum):
    ADDR = 0
    IM = 1


def parseOperation(opcode):
    # Lookup table
    opLookup = opInfo()

    # Extend trailing zeroes
    parse = opcode
    for _ in range(5 - len(opcode)):
        parse = '0' + parse

    # Read chars from right to left
    op = opLookup[int(parse[-2:])]
    parse = parse[:-2]
    modes = [Modes(int(x)) for x in parse]

    print(op[0].name, [el.name for el in modes])
    return (op, modes)


def parseMode(mode, val, mem):
    if mode is Modes.ADDR:
        return int(mem[int(val)])
    else:
        return int(val)


def executeOperation(inputValues, mem, pc, opInfo):
    # Get op and modes
    op, incr = opInfo[0]
    modes = opInfo[1]
    # Reverse inputValues
    inputs = inputValues[::-1]

    params = []
    for index, _ in enumerate(range(incr)):
        if index is not incr:
            params.append(parseMode(modes.pop(), mem[pc + index + 1], mem))

    # Dest (never immediate, so don't parseMode)
    dest = int(mem[pc+incr])

    if op is Opcodes.ADD:
        mem[dest] = str(params[0] + params[1])

    elif op is Opcodes.MUL:
        mem[dest] = str(params[0] * params[1])

    elif op is Opcodes.INP:
        mem[dest] = inputs.pop()
        return (incr + 1, "INPUT", "")

    elif op is Opcodes.OUT:
        return (incr + 1, "OUT", params[0])

    elif op is Opcodes.JIT:
        if (params[0]) != 0:
            return (params[1] - pc, "", "")

    elif op is Opcodes.JIF:
        if params[0] == 0:
            return (params[1] - pc, "", "")

    elif op is Opcodes.SLE:
        if params[0] < params[1]:
            mem[dest] = str(1)
        else:
            mem[dest] = str(0)

    elif op is Opcodes.SEQ:
        if params[0] == params[1]:
            mem[dest] = str(1)
        else:
            mem[dest] = str(0)
    else:
        print("Op HALT = '99', exiting")
        return (incr + 1, "HALT", "")

    return (incr + 1, "", "")  # Include operator


def executeIntCode(mem, inputVal, pc):

    output = ""
    while True:
        opInfo = parseOperation(mem[pc])
        (incr, output, opt) = executeOperation(inputVal, mem, pc, opInfo)
        pc += incr
        if output == "INPUT":
            del inputVal[0]
        if output == "OUT":
            return (opt, pc)
        if output == "HALT":
            return ("HALT", pc)
