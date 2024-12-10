import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def delay(dut, cycle_wait_count):
    for _ in range(cycle_wait_count):
        await RisingEdge(dut.s_tick)

@cocotb.test()
async def rx_test(dut):
     # 8.68 microseconds is 115200 bps
    cocotb.start_soon(Clock(dut.s_tick, 8680 * 16, units="ns").start())

    dut.reset.value = 1
    dut.rx.value = 1
    await delay(dut, 2)

    dut.reset.value = 0;
    data_bits = [1, 1, 1, 0, 1, 0, 0, 1]
    data = [0] + data_bits + [1]

    for i in range(len(data)):
        dut.rx.value = data[i]
        await delay(dut, 16)
        print(data[i], dut.rx.value, dut.dout.value, dut.bit_position.value)
    
    assert dut.dout.value == int(''.join(map(str, data_bits)), 2), "dout result is incorrect: %s" % (str(dut.dout.value))

    assert dut.rx_done.value == 1, "rx_done result is incorrect: should be 1, but is %s" % (str(dut.rx_done.value))
