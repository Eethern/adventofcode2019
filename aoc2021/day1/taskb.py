import numpy as np

if __name__=='__main__':
    with open('input.txt', 'r') as f:
        data = f.readlines()

    numbers = np.array(data, dtype=int)
    windowed = np.convolve(numbers, np.ones(3, dtype=int), 'valid')
    diffs = np.diff(windowed)
    increases = np.sum(diffs>0)

    print(f'Answer: {increases}')
        

        
