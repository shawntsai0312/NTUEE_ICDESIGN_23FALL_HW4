const fs = require('fs');

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
    [1, 9, 10],                 // 0    0.5
    [1, 7, 8, 9, 11],           // 0.5  1
    [1, 5, 6, 7, 8, 9, 10],     // 1    1.5
    [1, 3, 8, 9, 10, 11],       // 1.5  2
    [1, 3, 4, 8, 10, 11],       // 2    2.5
    [1, 2, 6, 9],               // 2.5  3
    [1, 2, 4, 5, 6, 10],        // 3    3.5
    [1, 2, 3, 5, 7, 8]          // 3.5  4
]

const a = aComponent.map(each => {
    // combine the components to get the value
    return each.reduce((acc, current) => acc + Math.pow(2, -current), 0)
})

const b = bComponent.map(each => {
    // combine the components to get the value
    return each.reduce((acc, current) => acc + Math.pow(2, -current), 0)
})


// Function to convert 8-bit binary (two's complement) to decimal
const binaryToDecimal = (binary) => {
    const isNegative = binary[0] === '1';
    const absoluteValue = parseInt(binary, 2);
    return isNegative ? -(256 - absoluteValue) : absoluteValue;
};

const padBinaryTo16Bits = binaryNumber => {
    // Ensure the binary input is less than 16 bits
    if (binaryNumber.length >= 16) {
        console.error('Binary input is already 16 bits or longer.');
        return null;
    }

    // Pad with leading zeros to make it 16 bits
    const paddedBinary = binaryNumber.padStart(16, '0');

    return paddedBinary;
};

// Read input file
const inputFilePath = '../pattern/Inn.dat';
const inputData = fs.readFileSync(inputFilePath, 'utf-8').split('\n');

const golFilePath = '../pattern/Gol.dat';
const golDataBin = fs.readFileSync(golFilePath, 'utf-8').split('\n');
const golDataDec = golDataBin.map(e => binaryToDecimal(e.trim()) / Math.pow(2, 15))

// Convert binary to decimal and write to output file
const outputFilePath = '../jsResults/OutPractice5.dat';
var mse = 0;
const outputData = inputData.map((line, index) => {
    const decimalX = binaryToDecimal(line.trim()) / 32;
    const absX = Math.abs(decimalX)
    const decimalY = golDataDec[index]
    let approximateY = a[Math.floor(absX * 2)] * absX + b[Math.floor(absX * 2)]
    if (absX == 4) approximateY = a[7] * absX + b[7]
    if (line.trim()[0] === '1') approximateY = 1 - Math.pow(2, -11) - approximateY + Math.pow(2, -12) + Math.pow(2, -14) + Math.pow(2, -15)
    else approximateY += Math.pow(2, -14) + Math.pow(2, -15)
    const error = approximateY - decimalY
    mse += error * error
    // console.log(a[Math.floor(decimalX * 2) + 8], b[Math.floor(decimalX * 2) + 8])
    return ("InputDec : " + decimalX.toString()
        + "\nInputBin : " + line
        + "\nGoldenDec : " + golDataBin[index]
        + "\nGoldenBin : " + decimalY.toString()
        + "\nApproximateDec : " + approximateY.toString()
        + "\nApproximateBin : " + padBinaryTo16Bits((approximateY * Math.pow(2, 15)).toString(2))
        + "\nApproximateHex : " + (approximateY * Math.pow(2, 15)).toString(16)
        + "\nError : " + error.toString()
        + "\n")
});

fs.writeFileSync(outputFilePath, outputData.join('\n'), 'utf-8');

console.log(mse);
mseGolForm = mse * Math.pow(2, 30)
console.log(mseGolForm)