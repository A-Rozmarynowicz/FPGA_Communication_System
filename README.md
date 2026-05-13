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

The synthesizable structure of the translator is shown below in the figure 1. Note that the "Master_Interface" is the top module acting as the translator. Also, internal error and warning signals were skipped in this schematic. Notes next to arrows inside the main node describe buses' widths.

<p align="center">
<img src="./Images/Master_Interface_Schematic.png" alt="./Images/Master_Interface_Schematic.png" width="550"><br>
<em>Figure 1: Master Interface internal diagram.</em>
</p>

Structure of the simulation testbench is shown in figure 2. Both the parallel transceiver and the UART transceiver store data in RAM, to assert correctness of data transfers. Parallel transceiver on the left sends, reads, and compares data from the UART transceiver on the right. Note that widths of buses were omitted in the diagram: they are however compliant with what is shown on Figure 1, where the parallel bus width is customizable.

<p align="center">
<img src="./Images/Testbench_Diagram.png" alt="./Images/Testbench_Diagram.png" width="550"><br>
<em>Figure 2: Simulation testbench diagram.</em>
</p>

In hardware implementation a VIO core plays the role of the parallel transceiver, and a PC serial terminal along with an onboard USB-UART bridge play the role of the UART transceiver.

## Example
In figures 3 and 4 example waveforms are presented. In the first case, a letter "" (... hexadecimal) was sent from VIO to a PuTTY terminal, through the FPGA unit and a USB-UART bridge. In the second case, a letter "" (... hexadecimal) was sent the other way around.

<p align="center">
<img src="" alt="..." width="550"><br>
<em>Figure 3: Transfer from FPGA to PC.</em>
</p>

<p align="center">
<img src="" alt="..." width="550"><br>
<em>Figure 4: Transfer from PC to FPGA.</em>
</p>


