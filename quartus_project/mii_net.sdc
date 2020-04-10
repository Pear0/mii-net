create_clock -name i_sys_clk -period 20 [get_ports {i_sys_clk}]

# 25MHz for 100Mbps, we'll leave it at 50MHz
create_clock -name rx_clk -period 20 [get_ports {enet_rx_clk}]

# 25MHz for 100Mbps, we'll leave it at 50MHz
create_clock -name tx_clk -period 20 [get_ports {enet_tx_clk}]

derive_pll_clocks -create_base_clocks

derive_clock_uncertainty

set_false_path -from [get_ports {i_nreset i_switches[0] i_switches[1] i_switches[2] i_switches[3] i_switches[4] i_switches[5] i_switches[6] i_switches[7] i_switches[8] i_switches[9] i_switches[10] i_switches[11] i_switches[12] i_switches[13] i_switches[14] i_switches[15]}]
set_false_path -to [get_ports {ssegs[0][0] ssegs[0][1] ssegs[0][2] ssegs[0][3] ssegs[0][4] ssegs[0][5] ssegs[0][6] ssegs[1][0] ssegs[1][1] ssegs[1][2] ssegs[1][3] ssegs[1][4] ssegs[1][5] ssegs[1][6] ssegs[2][0] ssegs[2][1] ssegs[2][2] ssegs[2][3] ssegs[2][4] ssegs[2][5] ssegs[2][6] ssegs[3][0] ssegs[3][1] ssegs[3][2] ssegs[3][3] ssegs[3][4] ssegs[3][5] ssegs[3][6] ssegs[4][0] ssegs[4][1] ssegs[4][2] ssegs[4][3] ssegs[4][4] ssegs[4][5] ssegs[4][6] ssegs[5][0] ssegs[5][1] ssegs[5][2] ssegs[5][3] ssegs[5][4] ssegs[5][5] ssegs[5][6] ssegs[6][0] ssegs[6][1] ssegs[6][2] ssegs[6][3] ssegs[6][4] ssegs[6][5] ssegs[6][6] ssegs[7][0] ssegs[7][1] ssegs[7][2] ssegs[7][3] ssegs[7][4] ssegs[7][5] ssegs[7][6]}]
