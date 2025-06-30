
create_clock -period 20.000 -name {clock_50} [get_ports {clk}]

create_generated_clock -divide_by 100000 -source [get_ports {clk}] -name clk_div_20 {q[20]}
create_generated_clock -divide_by 100000 -source [get_ports {clk}] -name clk_div_21 {q[21]}

create_generated_clock -source {vgaText_inst|clkGen|altpll_component|auto_generated|pll1|clk[0]} -divide_by 2 -duty_cycle 50.00 -name vgaClk {VGA_text:vgaText_inst|vgaClk}
