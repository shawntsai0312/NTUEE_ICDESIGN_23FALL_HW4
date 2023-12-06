const fs = require('fs');

// Sigmoid
const sigmoid = x => 1 / (1 + Math.exp(-x));

const sigmoidA = () => {
    const arr = [];
    for (let i = -4; i < 4; i += 0.5) arr.push(2 * (sigmoid(i + 0.5) - sigmoid(i)))
    return arr
}

const a = sigmoidA()

const sigmoidB = () => {
    const arr = [];
    for (let i = -4; i < 4; i += 0.5) arr.push(2 * (i + 0.5) * sigmoid(i) - 2 * i * sigmoid(i + 0.5))
    return arr
}

const b = sigmoidB()

// Function to convert 8-bit binary (two's complement) to decimal
const binaryToDecimal = (binary) => {
    const isNegative = binary[0] === '1';
    const absoluteValue = parseInt(binary, 2);
    return isNegative ? -(256 - absoluteValue) : absoluteValue;
};

// Read input file
const inputFilePath = '../pattern/Inn.dat';
const inputData = fs.readFileSync(inputFilePath, 'utf-8').split('\n');

// Convert binary to decimal and write to output file
const outputFilePath = '../pattern/OutApproximate.dat';
var mse = 0;
const outputData = inputData.map((line) => {
    const decimalX = binaryToDecimal(line.trim()) / 32;
    const decimalY = sigmoid(decimalX)
    const approximateY = a[Math.floor(decimalX * 2) + 8] * decimalX + b[Math.floor(decimalX * 2) + 8]
    const error = approximateY - decimalY
    mse += error * error
    // console.log(a[Math.floor(decimalX * 2) + 8], b[Math.floor(decimalX * 2) + 8])
    return "Input : " + decimalX.toString() + "\nPrecise : " + decimalY.toString() + "\nApproximate : " + approximateY.toString() + "\nError : " + error.toString() + "\n"
});

fs.writeFileSync(outputFilePath, outputData.join('\n'), 'utf-8');

console.log(mse);
