/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "verilog/dv/caravel/defs.h"

/**
 * Sets up the RV32 to talk to the Zube interface.
 *
 * When an interrupt fires, RV32 checks Status OUT.
 * If Status OUT is not what it was last time, it reads Data OUT.
 * It takes the value in Data OUT, adds one, and writes it back to Data IN.
 * It then writes a new value to Status IN.
 */
void main()
{
	/*
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |

	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |

	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |

	*/

	// 8 inputs for Z80 Address Bus
	reg_mprj_io_8 =   GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_9 =   GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_10 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_11 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_12 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_13 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_14 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_15 =  GPIO_MODE_USER_STD_INPUT_NOPULL;

	// 8 I/O pins for Z80 Data Bus
	reg_mprj_io_16 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_17 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_18 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_19 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_20 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_21 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_22 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
	reg_mprj_io_23 = GPIO_MODE_USER_STD_BIDIRECTIONAL;

	// 5 control signals (not the wrapper goes from 27:0, not 35:8 like we do)

	// .z80_bus_dir(io_out[16]),
	reg_mprj_io_24 =  GPIO_MODE_USER_STD_OUTPUT;
	// .z80_read_strobe_b(io_in[17]),
	reg_mprj_io_25 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	// .z80_write_strobe_b(io_in[18]),
	reg_mprj_io_26 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	// .z80_m1(io_in[19]),
	reg_mprj_io_27 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	// .z80_ioreq_b(io_in[20]),
	reg_mprj_io_28 =  GPIO_MODE_USER_STD_INPUT_NOPULL;

	/* Activate my project */
	reg_la1_iena = 0; // input enable off
	reg_la1_oenb = 0; // output enable bar low (enabled)
	reg_la1_data = 1 << 5;

	/* Apply configuration */
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1);

	// reset design with 0bit of 1st bank of LA
	reg_la0_data = 1;
	reg_la0_oenb = 0;
	reg_la0_iena = 0;
	reg_la0_data = 0;
	reg_la0_data = 1;

	volatile uint32_t* const p_z80_base_address = (volatile uint32_t*) 0x30000000;
	volatile uint32_t* const p_data = (volatile uint32_t*) 0x30000004;
	volatile uint32_t* const p_control = (volatile uint32_t*) 0x30000008;
	volatile uint32_t* const p_status = (volatile uint32_t*) 0x3000000C;

	*p_z80_base_address = 0x81;

	// no interrupt polling example
	while (true) {
		const uint32_t status = *p_status;
		if (status & 0x00000001)
		{
			// Z80 has written to Data OUT, so echo the inverse
			uint32_t value = *p_data;
			*p_data = (value ^ 0xFF) & 0xFF;
		}
		if (status & 0x00000002)
		{
			// Z80 has written to Control OUT, so echo the inverse
			uint32_t value = *p_control;
			*p_control = (value ^ 0xFF) & 0xFF;
		}
	}
}

// End of file
