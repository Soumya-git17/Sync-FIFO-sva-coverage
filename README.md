# Synchronous FIFO: SVA and Functional Coverage Verification

Parameterized synchronous FIFO (DEPTH=8, DATA_WIDTH=8) verified with a
self-checking SystemVerilog testbench, SVA assertions, and a covergroup,
simulated with Verilator.

## Verification components
- **Scoreboard**: reference queue model, checks data, full, empty and count every cycle
- **SVA** (`sync_fifo_assertions.sv`): count bounds, flag equivalence, pointer behavior, data_out stability, reset values, pointer/count consistency
- **Functional coverage** (`sync_fifo_coverage.sv`): count bins and transitions, read/write request crosses, pointer wrap, reset
- **Directed tests**: fill, overflow, drain, underflow, simultaneous R/W (at empty, partial, full), pointer wrap, mid-operation reset
- **Random traffic**: 50/50, write-heavy, and read-heavy mixes

## Results
| Metric | Result |
|---|---|
| Covergroup | 100% (51/51 bins) |
| `cover property` | 5/5 |
| Toggle | 100% |
| Line (DUT, Verilator `std` package excluded) | 100% |
| Assertions / scoreboard | 0 failures |

## Run
```
make run    # build, simulate, annotate coverage
make cov    # filtered line coverage summary
make lint
make wave
```

## Notes
- Verilator does not support `ignore_bins` in crosses, so crosses that
  contain impossible bins (accepted read at empty, accepted write at full)
  were removed rather than ignored.
- Coverage transition bins use literals (`7 => 8`, `7 => 0`), so the coverage
  module assumes DEPTH=8.
- The raw Verilator summary shows low line/branch/expr percentages because it
  includes Verilator's built-in `std.sv`. `make cov` filters it out.

## Future work
Formal verification (SymbiYosys), mutation testing, UVM testbench.
