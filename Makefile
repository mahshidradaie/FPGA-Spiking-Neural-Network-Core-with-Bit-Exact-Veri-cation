IVERILOG ?= iverilog
VVP      ?= vvp
RTL = rtl/lif_neuron.v rtl/syn_acc.v rtl/snn_core.v
TICKS = 2000

.PHONY: all sim golden compare plot uart clean
all: compare

weights.hex: scripts/gen_weights.py
	python3 scripts/gen_weights.py weights.hex

sim_out/rtl_spikes.txt: $(RTL) tb/tb_snn_core.v weights.hex
	mkdir -p sim_out
	$(IVERILOG) -g2005 -o sim_out/tb.vvp $(RTL) tb/tb_snn_core.v
	$(VVP) sim_out/tb.vvp

sim: sim_out/rtl_spikes.txt

golden: weights.hex
	mkdir -p sim_out
	python3 scripts/golden_model.py weights.hex $(TICKS) sim_out/golden_spikes.txt

compare: sim golden
	python3 scripts/compare.py sim_out/rtl_spikes.txt sim_out/golden_spikes.txt

plot: sim
	python3 scripts/plot_raster.py sim_out/rtl_spikes.txt docs/raster.png

uart: weights.hex
	mkdir -p sim_out
	$(IVERILOG) -g2005 -o sim_out/uart.vvp $(RTL) rtl/uart_tx.v rtl/snn_top.v tb/tb_uart_frame.v
	$(VVP) sim_out/uart.vvp

clean:
	rm -rf sim_out weights.hex
