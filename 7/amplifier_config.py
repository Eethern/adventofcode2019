from intcode_machine import executeIntCode


class Amplifier:
    def __init__(self, mem):
        self.mem = mem.copy()
        self.pc = 0

    def resetMemory(self, mem):
        self.mem = mem.copy()
        self.pc = 0


def runAmpProgram(amp, inputs):
    (cmd, pc) = executeIntCode(amp.mem, inputs, amp.pc)
    amp.pc = pc
    return cmd


def tryPhaseCombination(amps, phases, mode):
    # Reverse phase list (For usage of pop())
    phases = phases[::-1]
    # First input is 0
    prevOutput = 0
    # Number of fb loop iterations
    iteration = 0
    # Run amps programs
    if mode == "feedback":
        # Loop until HALT detected in last machine
        while prevOutput != "HALT":
            for amp in amps:
                lastOutput = prevOutput
                if iteration == 0:
                    # Initial phase setup
                    phase = phases.pop()
                    prevOutput = runAmpProgram(amp, [phase, prevOutput])
                else:
                    # Just one input
                    prevOutput = runAmpProgram(amp, [prevOutput])
                    # If halt detected, stop looping amps, grab lastOutput
                    if prevOutput == "HALT":
                        break
            iteration += 1
        return lastOutput
    else:
        # Normal execution (part 1)
        for index, amp in enumerate(amps):
            phase = phases.pop()
            prevOutput = runAmpProgram(amp, [phase, prevOutput])

    return prevOutput


# Function to generate permutations
def all_perms(elements):
    if len(elements) <= 1:
        yield elements
    else:
        for perm in all_perms(elements[1:]):
            for i in range(len(elements)):
                # nb elements[0:1] works in both string and list contexts
                yield perm[:i] + elements[0:1] + perm[i:]


def main():
    with open('input.txt') as FileObj:
        raw_data = FileObj.read()

    mem = list(raw_data.rstrip().split(','))

    # Create amp chain
    amps = []
    for amp in range(5):
        uniqueMem = mem.copy()
        amps.append(Amplifier(uniqueMem))

    # Create permutations, keep as iterator
    permutations = all_perms(list(range(5, 10)))

    # Calculate strongest signal
    strongestSignal = 0
    for perm in permutations:
        # Reset memory for all amps
        for amp in amps:
            amp.resetMemory(mem)

        print("Testing perm ", perm)
        strongestSignal = max(strongestSignal, tryPhaseCombination(amps, perm, "feedback"))
        print("Strongest signal: ", strongestSignal)


if (__name__ == '__main__'):
    main()
