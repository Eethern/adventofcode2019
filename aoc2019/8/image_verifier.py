from collections import deque


class Layer:
    def __init__(self, width, height, data):
        self.width = width
        self.height = height
        self.data = data


def extractLayer(raw_data, width, height):
    layers = []
    for h in range(height):
        layerRow = []
        for w in range(width):
            layerRow.append(raw_data.popleft())
        layers.append(layerRow)
    # print("Layer in cur extract: ", layers)
    return Layer(width, height, layers)


def countDigitInLayer(layer, digit):
    count = 0
    for row in layer.data:
        for char in row:
            count += 1 if char is digit else 0
    return count


def overlayLayers(layers, render):
    width = layers[0][0].width
    height = layers[0][0].height

    # Initialize not rendered
    for index in range(len(render)):
        render[index] = (render[index], False)

    # Loop over all layer pixels
    for layer in layers:
        layer = layer[0]
        # Loop over rows
        for rind, row in enumerate(layer.data):
            # Loop over columns
            for cind in range(width):
                color = int(row[cind])
                index = rind * width + cind
                if ((color != 2) and (render[index][1] is False)):
                    render[index] = (color, True)

    render = [str(pixel) for (pixel, cond) in render]
    return render


def printImage(render, width, height):
    for index, char in enumerate(render):
        if char == '2':
            render[index] = ' '
        if char == '1':
            render[index] = '░'
        if char == '0':
            render[index] = '█'

    image = "".join(render)
    for r in range(height):
        print(image[width*r:width*(r + 1)])


def main():
    with open('input.txt') as FileObj:
        raw_data = deque(FileObj.read().rstrip())

    (width, height) = 25, 6

    layers = []
    minLayer = None
    while(len(raw_data) != 0):
        layer = extractLayer(raw_data, width, height)
        layer = (layer, countDigitInLayer(layer, '0'))
        layers.append(layer)
        minLayer = layer if (minLayer is None or layer[1] < (minLayer[1])) else minLayer

    numOnes = countDigitInLayer(minLayer[0], '1')
    numTwos = countDigitInLayer(minLayer[0], '2')

    print("Result: ", numOnes * numTwos)

    # Create transparent render list
    render = [2] * width * height

    render = overlayLayers(layers, render)
    print("Decoded Image")
    printImage(render, width, height)



if (__name__ == '__main__'):
    main()
