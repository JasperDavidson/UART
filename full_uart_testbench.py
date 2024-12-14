import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def delay(dut, cycle_wait_count, oversampling):
    for _ in range(cycle_wait_count):
        await RisingEdge(dut.tx_s_tick)
    
    for _ in range(cycle_wait_count * oversampling):
        await RisingEdge(dut.rx_s_tick)
        
@cocotb.test()
async def full_test(dut):
    # 8.68 microseconds is 115200 bps for the baud rate
    baud_rate = 8680;
    oversampling = 16;
    cocotb.start_soon(Clock(dut.tx_s_tick, baud_rate * oversampling, units="ns").start()) # Makes the period x times longer than the rx clock for x oversampling
    cocotb.start_soon(Clock(dut.rx_s_tick, baud_rate, units="ns").start())
    
    # Reset rx and tx
    dut.tx_reset.value = 1
    dut.rx_reset.value = 1
    await delay(dut, 1, oversampling)
    dut.tx_reset.value = 0
    dut.rx_reset.value = 0
    
    # Set up oversampling
    dut.oversampling.value = oversampling
    
    # Set up transmission
    tx_data = 0b11010101
    dut.tx_data.value = tx_data
    tx_data = int(f"{tx_data:0{8}b}"[::-1], 2)
    dut.tx_transmission.value = 1
    print(f"Cycle -1: RX={dut.rx.value}, TX={dut.tx.value}, TX_DONE={dut.tx_done.value}, DOUT={dut.dout.value}")
    await delay(dut, 1, oversampling)
    dut.tx_transmission.value = 0
    
    print("before while")
    
    i = 0
    while not dut.rx_done.value:
        print(f"Cycle {i}: RX={dut.rx.value}, TX={dut.tx.value}, TX_DONE={dut.tx_done.value}, DOUT={dut.dout.value}")
        dut.rx.value = dut.tx.value
        await delay(dut, 1, oversampling)  # Wait for one baud interval
        i += 1
        
        if i > 20:  # Break the loop if RX isn't completing
            raise RuntimeError("RX did not complete after 20 cycles!")
        
    print("past while")

    # Check UART results
    result = int(''.join(map(str, dut.dout.value)), 2)
    assert result == tx_data, "UART result is incorrect: %s != %s" % (result, tx_data)
    
    # Check rx_done and tx_done
    assert dut.tx_done.value == 1, "TX_DONE signal should be 1, not zero";
    assert dut.rx_done.value == 1, "TX_DONE signal should be 1, not zero";
