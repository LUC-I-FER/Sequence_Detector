# Overlapping Sequence Detector — SystemVerilog

A SystemVerilog implementation of a **Finite State Machine (FSM)** that detects the binary sequence `1011` from a serial input stream.

The detector supports **overlapping sequence detection**, meaning a detected sequence can share bits with the next sequence.

The project also includes a SystemVerilog testbench with:

- Multiple functional test cases
- Automatic PASS/FAIL checking
- Reset handling
- Clock generation
- VCD waveform generation
- Overlapping sequence verification

---

## Overview

The design uses a **Moore FSM**, where the output depends only on the current state.

The sequence being detected is:

```text
1011
````

For example, the input:

```text
1011011
```

contains two overlapping occurrences of `1011`:

```text
1011
   1011
```

The `out` signal becomes `1` when the FSM reaches the `S4` state.

---

## FSM States

| State  | Meaning                                   |
| ------ | ----------------------------------------- |
| `IDLE` | No part of the sequence has been detected |
| `S1`   | `1` detected                              |
| `S2`   | `10` detected                             |
| `S3`   | `101` detected                            |
| `S4`   | `1011` detected                           |

The states are defined using a SystemVerilog enumerated type:

```systemverilog
typedef enum logic [2:0] {
    IDLE,
    S1,
    S2,
    S3,
    S4
} state_t;
```

---

## State Transition Table

| Current State | Input `0` | Input `1` |
| ------------- | --------- | --------- |
| `IDLE`        | `IDLE`    | `S1`      |
| `S1`          | `S2`      | `S1`      |
| `S2`          | `IDLE`    | `S3`      |
| `S3`          | `S2`      | `S4`      |
| `S4`          | `S2`      | `S1`      |

The transition from `S4` allows the detector to preserve useful state information after detecting `1011`, enabling overlapping detection.

For example:

```text
Input:

1011011
```

The two occurrences are:

```text
1011
   1011
```

The FSM therefore detects the sequence twice.

---

# Design Architecture

The FSM consists of three main parts:

```text
              ┌─────────────────────┐
       in ───►│   Next-State Logic  │
              │                     │
              └──────────┬──────────┘
                         │
                    next_state
                         │
                         ▼
              ┌─────────────────────┐
       clk ──►│   State Register    │
       rst ──►│                     │
              └──────────┬──────────┘
                         │
                     cur_state
                         │
                         ▼
              ┌─────────────────────┐
              │    Output Logic     │
              │                     │
              └──────────┬──────────┘
                         │
                         ▼
                        out
```

---

# SystemVerilog Implementation

## State Declaration

The FSM states are represented using `typedef enum`:

```systemverilog
typedef enum logic [2:0] {
    IDLE,
    S1,
    S2,
    S3,
    S4
} state_t;
```

The current and next states are then declared as:

```systemverilog
state_t cur_state, next_state;
```

This provides a strongly typed representation of the FSM states.

---

## Sequential Logic

The current state is updated on every rising edge of the clock.

```systemverilog
always @(posedge clk) begin
    if (rst)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end
```

The reset returns the FSM to the `IDLE` state.

---

## Combinational Next-State Logic

The next state is determined from the current state and serial input:

```systemverilog
always @(*) begin
    case (cur_state)

        IDLE: begin
            if (in)
                next_state = S1;
            else
                next_state = IDLE;
        end

        S1: begin
            if (in)
                next_state = S1;
            else
                next_state = S2;
        end

        S2: begin
            if (in)
                next_state = S3;
            else
                next_state = IDLE;
        end

        S3: begin
            if (in)
                next_state = S4;
            else
                next_state = S2;
        end

        S4: begin
            if (in)
                next_state = S1;
            else
                next_state = S2;
        end

    endcase
end
```

---

## Moore Output

The output is generated from the current state:

```systemverilog
assign out = (cur_state == S4);
```

Therefore:

```text
cur_state = S4
      ↓
    out = 1
```

When the FSM is in any other state:

```text
cur_state != S4
      ↓
    out = 0
```

---

# Testbench

The project includes a SystemVerilog testbench:

```text
testbench.sv
```

The testbench provides:

* Clock generation
* Reset generation
* Serial input stimulus
* Expected output comparison
* Automatic PASS/FAIL reporting
* Multiple test cases
* VCD waveform generation

---

# Testbench Tasks

The testbench uses reusable SystemVerilog tasks to make the verification code easier to understand and maintain.

## `send_bit()`

The `send_bit()` task sends one input bit and checks the expected output.

```systemverilog
task send_bit(
    input logic bit_value,
    input logic expected_out
);
```

For example:

```systemverilog
send_bit(1, 0);
```

means:

```text
Input        = 1
Expected out = 0
```

While:

```systemverilog
send_bit(1, 1);
```

means:

```text
Input        = 1
Expected out = 1
```

The task automatically prints whether the result is correct:

```text
Time=56 | in=1 | out=1 | expected=1 | PASS
```

or:

```text
Time=56 | in=1 | out=0 | expected=1 | FAIL
```

---

## `reset_dut()`

The `reset_dut` task resets the detector before every test case.

```systemverilog
task reset_dut;
```

This ensures that each test starts from the `IDLE` state and that the test cases are independent of each other.

---

# Verification Test Cases

Three functional test cases are currently implemented.

---

## Test Case 1 — Basic Detection

### Input

```text
101101011
```

### Expected Output

```text
000100001
```

The input contains two occurrences of `1011`.

```text
1011
     1011
```

Therefore, the output should become `1` at the corresponding detection points.

---

## Test Case 2 — Overlapping Detection

### Input

```text
1011011
```

### Expected Output

```text
0001001
```

The sequence contains two overlapping occurrences:

```text
1011
   1011
```

This test verifies that the FSM correctly supports overlapping sequence detection.

The output should be:

```text
0001001
```

with `out = 1` for both detected sequences.

---

## Test Case 3 — Edge Case Detection

### Input

```text
101101
```

### Expected Output

```text
000100
```

The first occurrence of `1011` is detected.

The remaining input does not contain another complete `1011` sequence.

Therefore, the expected output is:

```text
000100
```

This verifies that the detector does not assert `out` for an incomplete sequence.

---

# Clock Generation

The testbench generates a clock using:

```systemverilog
always #5 clk = ~clk;
```

This produces a clock with:

```text
Period = 10 time units
```

and approximately:

```text
50% duty cycle
```

The input is changed on the falling edge of the clock:

```systemverilog
@(negedge clk);
in = bit_value;
```

The DUT samples the input on the following rising edge:

```systemverilog
@(posedge clk);
```

This prevents input changes from occurring at the same time as the state update.

---

# Automatic Verification

Instead of manually checking the simulation output, the testbench compares the actual output against the expected output:

```systemverilog
if (out == expected_out)
    $display("... PASS");
else
    $display("... FAIL");
```

This makes the testbench capable of automatically identifying incorrect behavior.

Example:

```text
Time=26 | in=1 | out=0 | expected=0 | PASS
Time=36 | in=0 | out=0 | expected=0 | PASS
Time=46 | in=1 | out=0 | expected=0 | PASS
Time=56 | in=1 | out=1 | expected=1 | PASS
```

---

# VCD Waveform Generation

The testbench generates a VCD waveform file using:

```systemverilog
initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, seq_detector_tb);
end
```

After simulation, the following file is generated:

```text
dump.vcd
```

The waveform can be opened using:

* GTKWave
* EPWave on EDA Playground
* Other VCD-compatible waveform viewers

The waveform can be used to inspect signals such as:

```text
clk
rst
in
out
cur_state
next_state
```

---

# Simulation

The project can be simulated using:

* Icarus Verilog
* Verilator
* Questa / ModelSim
* Xilinx Vivado Simulator

For Icarus Verilog with SystemVerilog support:

```bash
iverilog -g2012 -o sim design.sv testbench.sv
```

Run the compiled simulation:

```bash
vvp sim
```

The `-g2012` option enables SystemVerilog-2012 support.

---

# Example Simulation Output

A successful simulation produces output similar to:

```text
========================================
TEST CASE 1: BASIC DETECTION
Input    : 101101011
Expected : 000100001
========================================

----------------------------------------
Reset complete
----------------------------------------

Time=26 | in=1 | out=0 | expected=0 | PASS
Time=36 | in=0 | out=0 | expected=0 | PASS
Time=46 | in=1 | out=0 | expected=0 | PASS
Time=56 | in=1 | out=1 | expected=1 | PASS
...
```

The testbench then executes Test Case 2 and Test Case 3.

At the end:

```text
========================================
ALL TEST CASES COMPLETED
========================================
```

---

# Project Structure

```text
sequence-detector/
│
├── design.sv
├── testbench.sv
├── README.md
└── .gitignore
```

### `design.sv`

Contains the RTL implementation of the `1011` sequence detector.

### `testbench.sv`

Contains the SystemVerilog verification environment, including:

* Clock generation
* Reset
* Input stimulus
* Expected output checking
* Test cases
* PASS/FAIL reporting
* VCD generation

### `README.md`

Contains the project documentation.

---

# Learning Objectives

This project demonstrates:

* Finite State Machine design
* Moore FSM architecture
* Overlapping sequence detection
* SystemVerilog enumerated types
* SystemVerilog `logic` types
* Sequential RTL design
* Combinational next-state logic
* Synchronous reset
* SystemVerilog testbench development
* Task-based verification
* Automatic PASS/FAIL checking
* Clock and reset generation
* VCD waveform generation
* RTL simulation
* Basic RTL verification

---

# Possible Improvements

Future versions of this project could include:

* Replace `always @(*)` with `always_comb`
* Replace `always @(posedge clk)` with `always_ff`
* Add SystemVerilog Assertions (SVA)
* Add functional coverage
* Parameterize the detected sequence
* Create a generic N-bit sequence detector
* Support configurable sequence lengths
* Support selectable overlapping/non-overlapping modes
* Add randomized input generation
* Add a scoreboard
* Add automated regression testing
* Add a Makefile
* Add GitHub Actions for automated simulation
* Synthesize and test the design on an FPGA

---

# Tools

### HDL

**SystemVerilog**

### Simulator

**Icarus Verilog**

### Waveform Viewer

**GTKWave / EPWave**

### Development Environment

**EDA Playground**

---

This project is intended for educational and learning purposes.

You may modify, extend, and use the design for your own FPGA, RTL, and digital-design projects.

```
```
