# IC Design 23Fall HW4
##### author : B10901176 蔡弘祥

#### Before Running
```shell
source ./tool.sh
```

#### How To Run
```shell
./run.sh
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