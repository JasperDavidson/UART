import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def delay(dut, cycle_wait_count):
    for _ in range(cycle_wait_count):
        await RisingEdge(dut.s_tick)

@cocotb.test()
async def tx_test(dut):
    # 8.68 microseconds is 115200 bps for the baud rate
    cocotb.start_soon(Clock(dut.s_tick, 8680 * 16, units="ns").start())

    dut.reset.value = 1
    await delay(dut, 2)

    dut.reset.value = 0;
    dut.transmission.value = 1
    dut.data.value = 0b11101001
    await delay(dut, 1)

    data = []
    for _ in range(11):
        data.insert(0, dut.tx.value)
        await delay(dut, 1)
    
    print(data)
    
    # Deleting the idle, start, and stop bits from the stream respectivelyz
    del data[9]
    del data[8]
    del data[0]
    
    assert int(''.join(map(str, data)), 2) == dut.data.value, "tx result is incorrect: %s" % (str(dut.data.value))
    assert dut.tx_done.value == 1, "tx_done result is incorrect, should be 1"