# APB UART Peripheral in Verilog

A synthesizable APB-based UART peripheral implemented in Verilog.

## Features

- UART Transmitter (8-bit)
- UART Receiver (8-bit)
- Parameterized design
- APB slave interface
- Register-based architecture
- Self-checking testbench
- Directed and random tests
- Loopback verification
- GTKWave compatible

---

## Block Diagram

```
           APB Master
                |
      ---------------------
      |  APB UART Bridge   |
      ---------------------
                |
             UART Wrapper
            /            \
      UART TX          UART RX
            \            /
             Serial Line
```

---

## Register Map

| Address | Register | Access |
|---------|----------|--------|
| 0x00    | TX_DATA  | Write  |
| 0x04    | RX_DATA  | Read   |
| 0x08    | STATUS   | Read   |

### Status Register

| Bit | Description |
|-----|-------------|
| 0   | TX Busy     |
| 1   | TX Done     |
| 2   | RX Ready    |
| 3   | Frame Error |

---

## Verification

### Directed Tests

- 0x00
- 0xFF
- 0x55
- 0xAA
- 0x7F
- 0x80
- 0xA5
- 0x3C
- 0xB8
- 0x1C

### Random Tests

20 random transactions

### Self-checking

The testbench automatically compares transmitted and received data and reports:

- PASS
- FAIL

### Summary

```
TOTAL TEST = 30
TOTAL PASS = 30
TOTAL FAIL = 0

********* ALL TESTS PASSED *********
```

---

## Tools Used

- Verilog HDL
- Vivado Simulator
---

## Future Improvements

- TX FIFO
- RX FIFO
- Interrupt generation
- Parity support
- PSLVERR support
- UVM testbench
