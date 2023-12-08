# IC Design 23Fall HW4
##### author : B10901176 蔡弘祥

#### Before Running
```shell
source ./tool.sh
```

#### How To Run
```shell
./run.sh
./debug.sh
```

#### How To Check Waveform
```shell
nWave &
```
1. Open sigmoid.vcd
2. Get signals : tb/DUT
3. Choose the signals wanna check

#### Input and Output Explanation
* Input : a 8-bit signed binary number (2's complement), divided by 32 to get decimal value
  * for example :
    * 1000_0000 represent -128, divided by 32 will be -4
    * 0111_1111 represent  127, divided by 32 will be 3.96875
* Output : a 16-bit unsigned binary number, divided by 2^15 to get decimal value
  * for example :
    * 1000_0000_0000_0000 represent 2^15, divided by 2^15 will be 1
    * 0010_0000_0000_0000 represent 2^13, divided by 2^15 will be 0.25

#### Goal
* Using basic logic gates and flip-flops to realize a "Sigmoid Approximator"
* For more Info, please checkout documents in doc/

#### Solution
1. Get the absolute value of the input (2's complement)
   * add a sign bit x[8] ( =x[7]), invert x[7,0] and add 1
2. Find out the range of the absolute value and determine a and b
   * 8-1 Mux
3. Calculate y = ax + b
4. If the input is negative, then invert every bit of y
   * y[15:0]^x[7]

#### JS Files Explanation
|JS File                  |Result File                  |Performance |Explanation                                        |
|-------------------------|-----------------------------|------------|---------------------------------------------------|
|js/sigmoidApproximate.js |jsResults/OutApproximate.dat |0.000546 |directly use secant lines to approximate on [-4,4] |
|js/sigmoidPractice.js    |jsResults/OutPractice.dat    |0.004392 |1. use the absolute value (if negative, invert bits) <br /> 2. use secant lines to approximate on [0,4] <br /> 3. if input is negative, invert output bits|
|js/sigmoidPractice2.js   |jsResults/OutPractice2.dat   |0.000537 |1. use the absolute value (if negative, invert bits and add 1) <br /> 2. use secant lines to approximate on [0,4] <br /> 3. if input is negative, invert output bits|
|js/sigmoidPractice3.js   |jsResults/OutPractice3.dat   |0.000302 |1. use the absolute value (if negative, invert bits and add 1) <br /> 2. use self-defined constants to approximate on [0,4] <br /> 3. if input is negative, invert output bits|
|js/sigmoidPractice4.js   |jsResults/OutPractice4.dat   |0.000300 |1. use the absolute value (if negative, invert bits and add 1) <br /> 2. use self-defined constants to approximate on [0,4] <br /> 3. if input is negative, invert output bits|
|js/sigmoidPractice5.js   |jsResults/OutPractice5.dat   |0.000280 |1. use the absolute value (if negative, invert bits and add 1) <br /> 2. use self-defined constants to approximate on [0,4] <br /> 3. if input is negative, invert output bits <br /> 4. if negative, y[3:0] = 1011, if positive, y[3:0] = 0011|

#### Current Result
* non-pipelined : 
  * Clock cycle:               9.5 ns
  * Number of transistors:     3696
  * Total excution cycle:      256
  * Approximation Error Score: 1527.0
  * Performance Score:         8988672.0
* pipelined :
  * Clock cycle:               5.4 ns
  * Number of transistors:     5100
  * Total excution cycle:      258
  * Approximation Error Score: 1527.0
  * Performance Score:         7205320.0