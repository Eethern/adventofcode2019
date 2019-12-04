def isSorted(word):
    return all(word[i] <= word[i+1] for i in range(len(word) - 1))


def hasDoubles(word):
    return any(word[i] == word[i+1] for i in range(len(word) - 1))


def checkPassword(word):
    return isSorted(str(word)) and hasDoubles(str(word))


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
