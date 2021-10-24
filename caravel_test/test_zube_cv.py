#!/usr/bin/env python

"""
CocoTB Test Bench for the Caravel-wrapped Zube project.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, with_timeout
import random
import test_zube

clocks_per_phase = 10

@cocotb.test()
async def test_start(dut):
    """
    Check the design starts up.
    """
    clock = Clock(dut.clk, 25, units="ns")
    cocotb.fork(clock.start())

    dut.RSTB <= 0
    dut.power1 <= 0;
    dut.power2 <= 0;
    dut.power3 <= 0;
    dut.power4 <= 0;

    await ClockCycles(dut.clk, 8)
    dut.power1 <= 1;
    await ClockCycles(dut.clk, 8)
    dut.power2 <= 1;
    await ClockCycles(dut.clk, 8)
    dut.power3 <= 1;
    await ClockCycles(dut.clk, 8)
    dut.power4 <= 1;

    await ClockCycles(dut.clk, 80)
    dut.RSTB <= 1

    dut.z80_address_bus <= 0x00
    dut.z80_m1 <= 1
    dut.z80_ioreq_b <= 1
    dut.z80_write_strobe_b <= 1
    dut.z80_read_strobe_b <= 1
    dut.z80_data_bus_in <= BinaryValue("zzzzzzzz")

    # wait for reset
    await RisingEdge(dut.RSTB)

@cocotb.test()
async def test_all(dut):
    clock = Clock(dut.clk, 25, units="ns")

    cocotb.fork(clock.start())

    # wait for the reset signal - time out if necessary - should happen around 165us
    await with_timeout(FallingEdge(dut.uut.mprj.zube_wrapper0.reset_b), 1000, 'us')
    await RisingEdge(dut.uut.mprj.zube_wrapper0.reset_b)

    # This value is kind of arbitrary, but needs to be long enough for the
    # GPIO registers to be set, so that cocotb doesn't pull random garbage.
    await ClockCycles(dut.clk, 1000)

    # RV32 core resets Z80 address to 0x81 on start-up and writes to both
    # registers

    # Ping 10 bytes into the SoC, and get 10 bytes back
    for data_out in range(0, 10):
        # Write data byte and control byte
        await test_zube.test_z80_set(dut, 0x81, data_out)
        await test_zube.test_z80_set(dut, 0x82, data_out + 1)
        for y in range(0, 20):
            # Simulate 16x Z80 clock cycles, at 1/8 SoC clock speed. Plus an
            # extra cycle to ensure things don't always line up nicely
            await ClockCycles(dut.clk, (16 * 8) + 1)
            status = await test_zube.test_z80_get(dut, 0x83)
            # Check both IN registers are ready
            if (status & 0x0C) == 0x0C:
                found = True
                print(f"Took {y} loops to poll")
                break
        if not found:
            raise Exception("Failed to poll Z80 Status")
        data_in = await test_zube.test_z80_get(dut, 0x81)
        assert data_in == (data_out ^ 0xFF) & 0xFF
        control_in = await test_zube.test_z80_get(dut, 0x82)
        assert control_in == ((data_out + 1) ^ 0xFF) & 0xFF

    print("Test complete")
