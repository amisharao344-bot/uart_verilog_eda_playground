UART (Universal Asynchronous Receiver Transmitter) Using Verilog HDL

1. Project Overview

This project presents the design and simulation of a Universal Asynchronous Receiver Transmitter (UART) using Verilog Hardware Description Language. The implementation is verified using EDA Playground. UART is a widely used asynchronous serial communication protocol in embedded and digital systems.

2. Objectives

To design a UART transmitter and receiver using Verilog HDL

To understand asynchronous serial communication

To verify UART operation through simulation

3. Features

UART Transmitter (TX)

UART Receiver (RX)

Baud Rate: 9600

Data Format: 8N1 (8 data bits, No parity, 1 stop bit)

4. Design Description

The UART system is divided into modular blocks:

UART Transmitter: Converts parallel data into serial format

UART Receiver: Converts serial data back into parallel format

Top Module: Integrates transmitter and receiver

Testbench: Verifies functionality using simulation

5. Tools Used

Verilog HDL

EDA Playground

Icarus Verilog / Questa Simulator

6. Simulation Results

The simulation confirms correct UART frame generation, proper data transmission, and successful reception according to the specified baud rate.

7. Applications

Embedded system communication

FPGA-based serial interfaces

Digital communication learning

8. Conclusion

The UART module was successfully designed and verified using Verilog HDL. Simulation results confirm correct and reliable serial communication.

9. Author

Amisha Rao
Microelectronics and VLSI Engineering
