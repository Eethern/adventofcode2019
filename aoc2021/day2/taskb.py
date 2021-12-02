if __name__=='__main__':
    with open('input.txt', 'r') as f:
        lines = f.readlines()
            
    h, v, aim = 0, 0, 0

    vecs = {
        'forward': [1,1,0],
        'down': [0,0,1],
        'up': [0,0,-1]
    }

    for l in lines:
        orient, dist = l.split(' ')
        dist = int(dist)
        h += dist * vecs[orient][0]
        v += aim * dist * vecs[orient][1]
        aim += dist * vecs[orient][2]

    print(f'Answer: {h*v}')







        


