# Synchronous FIFO: SVA, Functional Coverage and UVM Verification

Parameterized synchronous FIFO (DEPTH=8, DATA_WIDTH=8) verified two ways:
a self-checking SystemVerilog testbench with SVA assertions and a covergroup
(Verilator), and a UVM testbench (Questa on EDA Playground).

## Repository layout
```
sync_fifo.sv              DUT
tb_sync_fifo.sv           self-checking SystemVerilog testbench
sync_fifo_assertions.sv   SVA assertions
sync_fifo_coverage.sv     functional coverage
Makefile                  Verilator flow
UVM/                      UVM testbench (EDA Playground files)
```

## Verification components

### SystemVerilog testbench (Verilator)
- **Scoreboard**: reference queue model, checks data, full, empty and count every cycle
- **SVA** (`sync_fifo_assertions.sv`): count bounds, flag equivalence, pointer behavior, data_out stability, reset values, pointer/count consistency
- **Functional coverage** (`sync_fifo_coverage.sv`): count bins and transitions, read/write request crosses, pointer wrap, reset
- **Directed tests**: fill, overflow, drain, underflow, simultaneous R/W (at empty, partial, full), pointer wrap, mid-operation reset
- **Random traffic**: 50/50, write-heavy, and read-heavy mixes

### UVM testbench (`UVM/`, UVM 1.2)
- **Interface** (`fifo_if`): clock, reset, request and flag signals shared by DUT and testbench
- **Sequence item** (`fifo_seq_item`): randomized `w_en`, `r_en`, `data_in`, plus observed `data_out`, `full`, `empty`
- **Driver**: applies one operation per transaction on the falling clock edge, so the DUT samples stable inputs
- **Monitor**: samples every cycle after reset and broadcasts each cycle as a transaction through an analysis port
- **Scoreboard**: queue-based reference model; checks `data_out` (including its one-cycle read latency), `full` and `empty` every cycle, and counts accepted and blocked reads and writes
- **Agent / Env**: sequencer, driver and monitor in one agent; the env connects the monitor to the scoreboard
- **Sequences** (`fifo_sequence.sv`):
  - `fifo_write_seq`: fill (also hits write-when-full)
  - `fifo_read_seq`: drain (also hits read-when-empty)
  - `fifo_rand_sequence`: constrained-random reads and writes, including simultaneous R/W
- **Test** (`fifo_test`): fill, drain, random traffic, drain again, then waits a few clocks so the final cycles are checked

## Results

| Metric | Result |
|---|---|
| Covergroup | 100% (51/51 bins) |
| `cover property` | 5/5 |
| Toggle | 100% |
| Line (DUT, Verilator `std` package excluded) | 100% |
| Assertions / scoreboard | 0 failures |
| UVM scoreboard | `<N>` cycles checked, 0 errors |
| UVM corner cases hit | `<N>` blocked writes (full), `<N>` blocked reads (empty) |

## Run

### SystemVerilog testbench
```
make run    # build, simulate, annotate coverage
make cov    # filtered line coverage summary
make lint
make wave
```

### UVM
Developed and run on EDA Playground with Siemens Questa (qrun 2025.2) and UVM 1.2.
Copy the files from `UVM/` into the playground, with `design.sv` as the design file
and `testbench.sv` as the testbench file (it includes the interface, the package
and `tb_top`). To run elsewhere, compile with `+incdir+UVM` and run the test `fifo_test`.

## Notes
- Verilator does not support `ignore_bins` in crosses, so crosses that
  contain impossible bins (accepted read at empty, accepted write at full)
  were removed rather than ignored.
- Coverage transition bins use literals (`7 => 8`, `7 => 0`), so the coverage
  module assumes DEPTH=8. The UVM scoreboard also hardcodes `DEPTH = 8`.
- The raw Verilator summary shows low line/branch/expr percentages because it
  includes Verilator's built-in `std.sv`. `make cov` filters it out.
- `UVM/design.sv` is the same DUT as `sync_fifo.sv`, kept so the UVM folder can be
  loaded into EDA Playground as-is.
- The UVM driver leaves one idle cycle between transactions, so back-to-back
  traffic is covered only by the SystemVerilog testbench.
- The UVM test applies reset once at start; mid-operation reset is covered in
  the SystemVerilog testbench only.