# UART
A Universal Asynchronous Receiver/ Transmitter Verilog project  
the customized UART include all features in design and provide dynamic configuration the UART as  needed, Consider a full-featured UART that uses additional input signals to specify the baud rate, type of parity bit- and the numbers of data bits and stop bits. The UART also includes  an error signal. In addition to the I/O signals of the uart-top design 
the following signals are presented: 
•  bd-rate; 2-bit input signal specifying the baud rate, which can be 1200,2400,4800. or 9600 baud 
•  d_num: 1-bit input signal specifying the number of data bits, which can be 7 or 8 
•  s_num: 1-bit input signal specifying the number of slop bits, which can be 1 or 2 
•  par: 2-bit input signal specifying the desired parity scheme. which can be no parity, even parity, or odd parity 
• err: 3-bit  output signal in which the bits indicate the existence of the parity error, frame error, and data overrun error

the project is consists of 4 sub modules:
  1. Parity generator
  2.Frame generator
  3.Baud rate generator
  4.Parallel input serial output (PISO) register
 -> the features of the UART in UART_full_features.JPG
 -> the summery of the project in UART.pdf
 ->every submodule has its test module
 ->the whole project in final_uart-1.v
