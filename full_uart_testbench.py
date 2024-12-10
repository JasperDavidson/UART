import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def delay(dut, cycle_wait_count):
    for _ in range(cycle_wait_count):
        await RisingEdge(dut.s_tick)
        
@cocotb.test()
async def full_test(dut):
    # 8.68 microseconds is 115200 bps for the baud rate
    cocotb.start_soon(Clock(dut.s_tick, 8680 * 16, units="ns").start())
    
    # Reset rx and tx
    dut.tx_reset.value = 1
    dut.rx_reset.value = 1
    await delay(dut, 1)
    dut.tx_reset.value = 0
    dut.rx_reset.value = 0
    
    # Transmit data
    tx_data = 0b10100101
    dut.tx_data.value = tx_data
    dut.tx_transmission.value = 1
    await delay(dut, 1)
    dut.tx_transmission.value = 0
    
    print("before while")
    
    i = 0
    while not dut.rx_done.value:
        await delay(dut, 1)  # Wait for one baud interval
        dut.rx.value = dut.tx.value
        print(f"Cycle {i}: RX={dut.rx.value}, TX={dut.tx.value}, TX_DONE={dut.tx_done.value}")
        i += 1
        
        if i > 20:  # Break the loop if RX isn't completing
            raise RuntimeError("RX did not complete after 20 cycles!")
        
    print("past while")

    # Check UART results
    result = int(''.join(map(str, dut.dout.value)), 2)
    assert result == tx_data, "UART result is incorrect: %s != %s" % (result, tx_data)
