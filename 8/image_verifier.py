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
        # print(minLayer[0].data, minLayer[1])
        # print("raw data: ", raw_data)
        # print("length of raw_data ", len(raw_data))

    numOnes = countDigitInLayer(minLayer[0], '1')
    numTwos = countDigitInLayer(minLayer[0], '2')

    print("Result: ", numOnes * numTwos)
if (__name__ == '__main__'):
    main()
