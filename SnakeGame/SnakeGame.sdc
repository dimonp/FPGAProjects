
create_clock -period 20.000 -name {clock_50M} [get_ports {clk}]
create_clock -period 100000 -name {clock_10k} [get_ports {ps2Clock}]

create_generated_clock -divide_by 1000 -source [get_ports {clk}] -name clk_div_16 {cnt[16]}
create_generated_clock -divide_by 1000 -source [get_ports {clk}] -name clk_div_17 {cnt[17]}

create_generated_clock -divide_by 100000 -source [get_ports {clk}] -name debounce {PS2_keyboard:keyboardPs2_inst|debounce:debounce_ps2_clk|result}

create_generated_clock -source {vgaText_inst|clockGen_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 50 -multiply_by 63 -duty_cycle 50.00 -name baseClk {vgaText_inst|clockGen_inst|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {vgaText_inst|clockGen_inst|altpll_component|auto_generated|pll1|clk[0]} -divide_by 2 -duty_cycle 50.00 -name vgaClk {VGA_text:vgaText_inst|vgaClk}
