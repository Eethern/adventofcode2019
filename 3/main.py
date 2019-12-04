import sys
from pyglet.gl import *

window = pyglet.window.Window()
window.height = 700
window.width = 1000


def manhattanDistance(x, y):
    return abs(x) + abs(y)


def calcNextPoint(word, startX, startY):
    direction = word[0]
    value = int(word[1:])
    x = startX
    y = startY

    if direction == 'U':
        return (x, y + value, 1)
    elif direction == 'D':
        return (x, y - value, -1)
    elif direction == 'L':
        return (x - value, y, -1)
    else:
        return(x + value, y, 1)


def drawPath(path, r, g, b):
    x = 6000
    y = 3000
    glColor3f(r,g,b)
    glBegin(GL_POLYGON)
    glVertex2f(5900,2900)
    glVertex2f(6100,2900)
    glVertex2f(6100,3100)
    glVertex2f(5900,3100)
    glEnd()

    glBegin(GL_LINES)
    for word in path:
        glVertex2f(x, y)
        (x, y, step) = calcNextPoint(word, x, y)
        # print("x: {x}".format(x=x))
        # print("y: {y}".format(y=y))
        glVertex2f(x,y)
    glEnd()

@window.event
def on_draw():
    filePath = sys.argv[1]
    f = open(filePath, 'r')

    paths = f.read().rstrip().split('\n')
    f.close()

    path1 = paths[0].split(',')
    path2 = paths[1].split(',')

    glClear(GL_COLOR_BUFFER_BIT)
    glLoadIdentity()
    glScalef(0.05, 0.05, 0.05)
    drawPath(path1, 255, 0, 0)
    drawPath(path2, 0, 255, 0)


def main():
    filePath = sys.argv[1]
    f = open(filePath, 'r')

    paths = f.read().rstrip().split('\n')
    f.close()

    path1 = paths[0].split(',')
    path2 = paths[1].split(',')
    # print(path1)
    # print(path2)

    # Store used coordinates in set
    coords = set([])

    # Store junctions in set
    junctions = set([])
    x = 0
    y = 0

    for word in path1:
        (nextX, nextY, step) = calcNextPoint(word, x, y)
        for xpos in range(x, nextX+step, step):
            coords.add((xpos, y))
            # print("Adding x: {xpos}".format(xpos=xpos))
        x = nextX

        for ypos in range(y, nextY+step, step):
            coords.add((x, ypos))
            # print("Adding y: {ypos}".format(ypos=ypos))
        y = nextY

    x = 0
    y = 0
    for word in path2:
        (nextX, nextY, step) = calcNextPoint(word, x, y)
        for xpos in range(x, nextX+step, step):
            # print("Adding x: {xpos}".format(xpos=xpos))
            if ((xpos, y)) in coords:
                junctions.add((xpos, y))
                coords.remove((xpos, y))
            x = nextX

        for ypos in range(y, nextY+step, step):
            # print("Adding y: {ypos}".format(ypos=ypos))
            if ((x, ypos)) in coords:
                junctions.add((x, ypos))
                coords.remove((x, ypos))
            y = nextY

    # Delete the (0, 0) junction
    junctions.discard((0, 0))

    distance = -1
    for pos in junctions:
        (x, y) = pos
        manHat = manhattanDistance(x, y)
        if (distance == -1):
            distance = manHat
        else:
            distance = min(distance, manHat)

    print("Shortest distance: {distance}".format(distance=distance))
    pyglet.app.run()


if (__name__ == '__main__'):
    main()
