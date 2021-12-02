def isSorted(word):
    return all(word[i] <= word[i+1] for i in range(len(word) - 1))


def hasDouble(word):
    return any(len(elem) == 2 for elem in splitGroup(word))


def splitGroup(word):
    return (''.join(x + ('' if x == nxt else ', ')
            for x, nxt in zip(word, word[1:] + word[-1]))).split(', ')


def checkPassword(word):
    return isSorted(str(word)) and hasDouble(str(word))


def main():
    start = 124075
    end = 580769
    count = 0

    for password in range(start, end + 1):
        word = str(password)

        if checkPassword(word):
            print(word)
            count+=1

    print("#passwords matching rules: {count}".format(count=count))


if (__name__ == '__main__'):
    main()
