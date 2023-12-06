const fs = require('fs');

// Sigmoid
const sigmoid = x => 1 / (1 + Math.exp(-x));

const aComponent = [
    [3, 4, 5, 6],   // 0    0.5
    [3, 4, 5],      // 0.5  1
    [3, 5, 6],      // 1    1.5
    [3],            // 1.5  2
    [4, 5],         // 2    2.5
    [4],            // 2.5  3
    [5],            // 3    3.5
    [6]             // 3.5  4
]

const bComponent = [
    [1, 9, 10, 12],             // 0    0.5
    [1, 7, 8, 9, 11],           // 0.5  1
    [1, 5, 6, 7, 8, 9, 10],     // 1    1.5
    [1, 3, 8, 9, 10, 11],       // 1.5  2
    [1, 3, 4, 8, 10, 11, 12],   // 2    2.5
    [1, 2, 6, 9],               // 2.5  3
    [1, 2, 4, 5, 6, 10, 12],    // 3    3.5
    [1, 2, 3, 5, 7, 8]          // 3.5  4
]

const a = aComponent.map(each => {
    return each.reduce((acc, current) => acc + Math.pow(2, -current), 0)
})

const b = bComponent.map(each => {
    return each.reduce((acc, current) => acc + Math.pow(2, -current), 0)
})


// Function to convert 8-bit binary (two's complement) to decimal
const binaryToDecimal = (binary) => {
    const isNegative = binary[0] === '1';
    const absoluteValue = parseInt(binary, 2);
    return isNegative ? -(256 - absoluteValue) : absoluteValue;
};

const k = Math.pow(2, -15);

// Read input file
const inputFilePath = '../pattern/Inn.dat';
const inputData = fs.readFileSync(inputFilePath, 'utf-8').split('\n');

// Convert binary to decimal and write to output file
const outputFilePath = '../jsResults/OutPractice4.dat';
var mse = 0;
const outputData = inputData.map((line) => {
    const decimalX = binaryToDecimal(line.trim()) / 32;
    const absX = Math.abs(decimalX)
    const decimalY = sigmoid(decimalX)
    let approximateY = a[Math.floor(absX * 2)] * absX + b[Math.floor(absX * 2)]
    if (absX == 4) approximateY = a[7] * absX + b[7]
    if (line.trim()[0] === '1') {
        approximateY = 1 - k - approximateY;
    }
    const error = approximateY - decimalY
    mse += error * error
    // console.log(a[Math.floor(decimalX * 2) + 8], b[Math.floor(decimalX * 2) + 8])
    return "Input : " + decimalX.toString() + "\nPrecise : " + decimalY.toString() + "\nApproximate : " + approximateY.toString() + "\nError : " + error.toString() + "\n"
});

fs.writeFileSync(outputFilePath, outputData.join('\n'), 'utf-8');

console.log(mse);
