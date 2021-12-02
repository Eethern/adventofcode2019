from enum import Enum


class Opcodes(Enum):
    ADD = 1  # Add
    MUL = 2  # Multiply
    INP = 3  # Input
    OUT = 4  # Output
    JIT = 5  # Jump if true
    JIF = 6  # Jump if false
    SLE = 7  # Store less than
    SEQ = 8  # store equal
    RBO = 9  # Relative base offset
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
        9: (Opcodes.RBO, 1),
        99: (Opcodes.HALT, 0)
    }


class Modes(Enum):
    ADDR = 0
    IM = 1
    REL = 2


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

    # print(op[0].name, [el.name for el in modes])
    return (op, modes)


def parseMode(mode, val, mem, regs):
    val = int(val)
    if mode is Modes.ADDR:
        return int(mem[val])
    elif mode is Modes.REL:
        return int(mem[regs['rel_base'] + val])
    else:
        return val


def parseDest(mode, val, mem, regs):
    val = int(val)
    if mode is Modes.REL:
        return val + regs['rel_base']
    else:
        return val


def executeOperation(mem, regs, opInfo):
    # Get op and modes
    op, incr = opInfo[0]
    modes = opInfo[1]

    params = []

    for index in range(incr):
        mode = modes.pop()
        param = int(mem[regs['pc'] + index + 1])

        params.append(parseMode(mode, param, mem, regs))
        if (index is incr - 1):
            dest = parseDest(mode, param, mem, regs)

    if op is Opcodes.ADD:
        mem[dest] = str(params[0] + params[1])

    elif op is Opcodes.MUL:
        mem[dest] = str(params[0] * params[1])

    elif op is Opcodes.INP:
        mem[dest] = str(regs['input'])

    elif op is Opcodes.OUT:
        print("Output: ", params[0])

    elif op is Opcodes.JIT:
        if (params[0]) != 0:
            regs['pc'] = params[1]
            return

    elif op is Opcodes.JIF:
        if params[0] == 0:
            regs['pc'] = params[1]
            return

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
    elif op is Opcodes.RBO:
        regs['rel_base'] += params[0]
    else:
        print("Op HALT = '99', exiting")

    regs['pc'] += incr + 1


def executeIntCode(mem, inputVal):
    regs = {'pc': 0, 'rel_base': 0, 'input': inputVal}

    while True:
        opInfo = parseOperation(mem[regs['pc']])
        executeOperation(mem, regs, opInfo)


def initMemory(size):
    mem = ['0'] * size
    return mem


def loadMemory(mem, program):
    for addr in range(len(program)):
        mem[addr] = program[addr]


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

    mem_size = 10000
    program = list(raw_data.rstrip().split(','))

    # init memory
    mem = initMemory(mem_size)
    # Load program
    loadMemory(mem, program)
    # Execute
    executeIntCode(mem, 1)


if (__name__ == '__main__'):
    main()
