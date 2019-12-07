from intcode_machine import executeIntCode
import time


class Amplifier:
    def __init__(self, mem):
        self.mem = mem

    def resetMemory(self, mem):
        self.mem = mem


def runAmpProgram(amp, inputs):
    return executeIntCode(amp.mem, inputs)


def tryPhaseCombination(amps, phases):
    # Reverse phase list
    phases = phases[::-1]
    # First input is 0
    prevOutput = 0
    # Run amps programs
    for index, amp in enumerate(amps):
        phase = phases.pop()
        # print("Trying phase {p} on amp {a} with input {i}".format(p=phase, a=index, i=prevOutput))
        prevOutput = runAmpProgram(amp, [phase, prevOutput])

    print(prevOutput)
    return prevOutput


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
        amps.append(Amplifier(mem))

    # Create permutations, keep as iterator
    permutations = all_perms(list(range(5)))
    # print(list(permutations))

    # Calculate strongest signal
    strongestSignal = 0
    for perm in permutations:
        # Reset memory for all amps
        for amp in amps:
            amp.resetMemory(mem)

        print("Testing perm ", perm)
        # time.sleep(0.5)
        strongestSignal = max(strongestSignal, tryPhaseCombination(amps, perm))

    print("Strongest signal: ", strongestSignal)




if (__name__ == '__main__'):
    main()
