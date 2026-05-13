![Electronics](https://img.shields.io/badge/Electronics-darkred)
![IT](https://img.shields.io/badge/IT-purple)

![Software](https://img.shields.io/badge/Software-lightblue)

# FPGA Communication System
Designed, simulated, and validated in hardware a communication system connecting a PC, an FPGA board, and an external transceiver using from-scratch UART and parallel interface implementations.

Author: Arkadiusz Rozmarynowicz.

## Table of contents
-

## General information
- Built a synthesizable structure that translates parallel bus communication to UART and vice versa
- Implemented fully parameterized modules from scratch:
    - UART interface, i.e. one that supports custom baud rates, clock frequencies, frame formats,
    - parallel interface, i.e. one that is compatible with custom bus widths and clock frequencies.
- Constructed a universal, robust, and parameterized FIFO buffer converter, that builds frames of a certain size from data frames of a different size, and also reports errors and warnings:
    - enables translation of UART frames of any size to parallel frames of any size, and vice versa.
- Built a simulation testbench consisting of two additional transceivers that exchanged data through the main module:
    - tested mutiple configurations and analyzed correctness on digital waveforms.
- Implemented the project on the Cmod S7 Digilent board, connecting a virtual parallel interface and a PC serial terminal:
    - utilized Virtual Input/Output (VIO) to simulate the parallel interface,
    - utilized Integrated Logic Analyzer (ILA) to analyze the correctness of communication.

## Technologies used
- IDE: Vivado 2025.
- Board: Cmod S7 by Digilent.
- Communication protocols:
    - UART
    - Parallel
- VIO and ILA cores.

## Project structure
Source files are contained within the [FPGA_Comm](/FPGA_Comm/) folder. There you can find design and simulations files.

The synthesizable structure of the translator is shown below. Note that the "Master_Interface" is the top module acting as the translator.