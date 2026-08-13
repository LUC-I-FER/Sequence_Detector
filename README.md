# Overlapping Sequence Detector — SystemVerilog

A SystemVerilog implementation of a **finite state machine (FSM)** that detects the binary sequence `1011` from a serial input stream.

The detector supports **overlapping sequence detection**, meaning a detected sequence can share bits with the next detected sequence.

## Overview

The design uses a **Moore FSM**, where the output depends only on the current state.

The sequence being detected is:

```text
1011
```

For example, the input:

```text
1011011
```

contains two overlapping occurrences of `1011`:

```text
1011
   1011
```

The `out` signal becomes `1` whenever the FSM reaches the `S4` state.

## FSM States

| State  | Meaning                                   |
| ------ | ----------------------------------------- |
| `IDLE` | No part of the sequence has been detected |
| `S1`   | `1` detected                              |
| `S2`   | `10` detected                             |
| `S3`   | `101` detected                            |
| `S4`   | `1011` detected                           |

### State Transition Table

| Current State | Input `0` | Input `1` |
| ------------- | --------- | --------- |
| `IDLE`        | `IDLE`    | `S1`      |
| `S1`          | `S2`      | `S1`      |
| `S2`          | `IDLE`    | `S3`      |
| `S3`          | `S2`      | `S4`      |
| `S4`          | `S2`      | `S1`      |

The transition from `S4` is what allows overlapping detection.

For example:

```text
Input: 1011011

First detection:
1011
^^^

Overlapping detection:
   1011
```

## Design Architecture

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

## SystemVerilog Features Used

This project uses SystemVerilog rather than traditional Verilog.

### Enumerated State Type

```systemverilog
typedef enum logic [2:0] {
    IDLE,
    S1,
    S2,
    S3,
    S4
} state_t;
```

This provides a strongly defined type for the FSM states.

### Sequential Logic

The state register is updated on the rising edge of the clock:

```systemverilog
always @(posedge clk) begin
    if (rst)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end
```

### Combinational Logic

The next state is determined from the current state and input:

```systemverilog
always @(*) begin
    case (cur_state)
        ...
    endcase
end
```

### Moore Output

The output is asserted when the FSM reaches `S4`:

```systemverilog
assign out = (cur_state == S4);
```

Therefore, `out` becomes `1` for one clock cycle when `1011` has been detected.

## Testbench

The project includes a SystemVerilog testbench that:

* Generates a 10-time-unit clock.
* Applies reset.
* Sends serial input bits to the detector.
* Displays `in` and `out`.
* Generates a VCD waveform file for waveform analysis.
* Tests overlapping sequence detection.

The test sequence used is:

```text
101101001011
```

It contains three occurrences of `1011`:

```text
1011
   1011

        1011
```

The expected detection points produce:

```text
out = 1
```

at the corresponding clock cycles.

## Simulation

The project can be simulated using tools such as:

* Icarus Verilog
* Verilator
* Questa/ModelSim
* Xilinx Vivado Simulator

For Icarus Verilog with SystemVerilog support:

```bash
iverilog -g2012 -o sim design.sv testbench.sv
vvp sim
```

The testbench also generates:

```text
dump.vcd
```

which can be opened using a waveform viewer such as GTKWave.

## Expected Output

The simulation prints messages similar to:

```text
Time=26 | in = 1 | out = 0
Time=36 | in = 0 | out = 0
Time=46 | in = 1 | out = 0
Time=56 | in = 1 | out = 1
...
```

An `out = 1` indicates that the sequence `1011` has been detected.

## Project Structure

A simple GitHub repository can use the following structure:

```text
sequence-detector/
│
├── design.sv
├── testbench.sv
├── README.md
└── .gitignore
```

### Files

**`design.sv`**

Contains the `seq_detector` FSM implementation.

**`testbench.sv`**

Contains the simulation testbench, clock generation, reset, input stimulus, output checking, and VCD generation.

**`README.md`**

Contains the project documentation.

## Possible Improvements

Future versions of this project could include:

* `always_ff` and `always_comb` instead of `always @(...)`.
* Automatic PASS/FAIL assertions in the testbench.
* Parameterized sequence detection.
* A configurable sequence length.
* A generic sequence detector capable of detecting arbitrary binary patterns.
* SystemVerilog assertions (SVA).
* Functional coverage.
* Automated simulation using a Makefile or CI pipeline.

## Learning Objectives

This project demonstrates:

* Finite State Machines
* Moore FSM design
* Overlapping sequence detection
* State encoding using `typedef enum`
* Sequential and combinational logic
* SystemVerilog testbench development
* Clock and reset generation
* Simulation and waveform generation
* Basic RTL verification

## License

This project is intended for educational and learning purposes. You may modify and extend it for your own FPGA/RTL projects.
