TOP = tb_sync_fifo
RTL = sync_fifo.sv
TB = tb_sync_fifo.sv
SVA = sync_fifo_assertions.sv
COVER = sync_fifo_coverage.sv

SRCS = $(RTL) $(SVA) $(COVER) $(TB)

.PHONY: all run debug lint cov clean wave

all: 
	verilator --binary --timing --trace --coverage --sv \
	--timescale 1ns/1ps --top-module $(TOP) $(SRCS)

run: all
	./obj_dir/V$(TOP)
	verilator_coverage --annotate coverage_report coverage.dat

debug:
	./obj_dir/V$(TOP) +DEBUG

lint:
	mkdir -p lint
	verilator --lint-only -Wall --Wno-IMPORTSTAR --Wno-SYNCASYNCNET --sv \
	--top-module $(TOP) $(SRCS) 2>&1 | tee lint/lint.log

cov:
	verilator_coverage --write-info cov.info coverage.dat
	lcov --remove cov.info '*std.sv' -o cov_clean.info
	lcov --summary cov_clean.info

clean:
	rm -rf obj_dir lint coverage_report
	rm -f  *.vcd coverage.dat cov.info cov_clean.info

wave:
	gtkwave tb_sync_fifo.vcd