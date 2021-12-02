import numpy as np

if __name__=='__main__':
    with open('input.txt', 'r') as f:
        data = f.readlines()

    numbers = np.array(data, dtype=int)
    print(np.sum(np.diff(numbers) > 0))
        

        
