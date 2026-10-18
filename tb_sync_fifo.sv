/* verilator coverage_off */
module tb_sync_fifo;

parameter DATA_WIDTH = 8;
parameter DEPTH      = 8;

logic clk;
logic rst_n;
logic r_en, w_en;
logic [DATA_WIDTH-1:0] data_in;
logic [DATA_WIDTH-1:0] data_out;
logic full, empty;

logic [$clog2(DEPTH):0] count;
logic [$clog2(DEPTH)-1:0] w_ptr, r_ptr;

sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n), .r_en(r_en), .w_en(w_en), .data_in(data_in),
    .data_out(data_out), .full(full), .empty(empty));

assign count = dut.count;
assign w_ptr = dut.w_ptr;
assign r_ptr = dut.r_ptr;

sync_fifo_assertions #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) sva_inst (
    .clk(clk), .rst_n(rst_n), .w_en(w_en), .r_en(r_en), .full(full), .empty(empty),
    .count(count), .w_ptr(w_ptr), .r_ptr(r_ptr), .data_out(data_out));

sync_fifo_coverage #(.DEPTH(DEPTH)) cov_inst (
    .clk(clk), .rst_n(rst_n), .count(count), .w_en(w_en), .r_en(r_en),
    .full(full), .empty(empty), .w_ptr(w_ptr), .r_ptr(r_ptr));

initial clk = 0;
always #5 clk = ~clk;


logic [DATA_WIDTH-1:0] exp_q [$];
logic [DATA_WIDTH-1:0] exp_out;
logic sb_valid;

int errors;
int n_writes, n_reads;
int n_overflow_try, n_underflow_try;
int n_simul;

always @(posedge clk) begin
    if (!rst_n) begin
        exp_q.delete();
        exp_out  <= '0;
        sb_valid <= 1'b0;
    end else begin
        sb_valid <= 1'b1;

        if (w_en && full)  n_overflow_try++;
        if (r_en && empty) n_underflow_try++;

        if (r_en && !empty) begin
            if (exp_q.size() == 0) begin
                $error("[%0t] SB: model queue empty on accepted read", $time);
                errors++;
            end else begin
                exp_out <= exp_q.pop_front();
                n_reads++;
            end
        end

        if (w_en && !full) begin
            exp_q.push_back(data_in);
            n_writes++;
        end

        if (w_en && !full && r_en && !empty) n_simul++;
    end
end

always @(negedge clk) begin
    if (sb_valid) begin
        if (data_out !== exp_out) begin
            $error("[%0t] DATA MISMATCH: got 0x%0h expected 0x%0h",
                    $time, data_out, exp_out);
            errors++;
        end
        if (empty !== (exp_q.size() == 0)) begin
            $error("[%0t] EMPTY MISMATCH: dut=%b model_size=%0d",
                    $time, empty, exp_q.size());
            errors++;
        end
        if (full !== (exp_q.size() == DEPTH)) begin
            $error("[%0t] FULL MISMATCH: dut=%b model_size=%0d",
                    $time, full, exp_q.size());
            errors++;
        end
        if (int'(count) !== exp_q.size()) begin
            $error("[%0t] COUNT MISMATCH: dut=%0d model=%0d",
                    $time, count, exp_q.size());
            errors++;
        end
    end
end

task automatic cycle(input logic w, input logic r, input logic [DATA_WIDTH-1:0] d);
    @(negedge clk);
    w_en    = w;
    r_en    = r;
    data_in = d;
endtask

task automatic idle(input int n = 1);
    repeat (n) cycle(1'b0, 1'b0, '0);
endtask

task automatic expect_flag(input string name, input logic actual, input logic expected);
    if (actual === expected) $display("PASS: %s", name);
    else begin
        $display("FAIL: %s (got %b, expected %b)", name, actual, expected);
        errors++;
    end
endtask

task automatic random_traffic(input int n_cycles, input int wr_pct, input int rd_pct);
    repeat (n_cycles)
        cycle(($urandom_range(99, 0) < wr_pct),
                ($urandom_range(99, 0) < rd_pct),
                DATA_WIDTH'($urandom));
endtask

initial begin
    errors = 0; n_writes = 0; n_reads = 0;
    n_overflow_try = 0; n_underflow_try = 0; n_simul = 0;
    rst_n = 0; r_en = 0; w_en = 0; data_in = 0;

    repeat (2) @(negedge clk);
    rst_n = 1;

    $display("\n--- Test 1: Fill FIFO ---");
    for (int i = 0; i < DEPTH; i++) cycle(1, 0, DATA_WIDTH'(i + 1));
    idle(2);
    expect_flag("FIFO is FULL", full, 1'b1);

    $display("\n--- Test 2: Write when FULL ---");
    cycle(1, 0, 8'hAA);
    idle(2);
    expect_flag("Still FULL after overflow attempt", full, 1'b1);

    $display("\n--- Test 3: Empty FIFO ---");
    for (int i = 0; i < DEPTH; i++) cycle(0, 1, '0);
    idle(2);
    expect_flag("FIFO is EMPTY", empty, 1'b1);

    $display("\n--- Test 4: Read when EMPTY ---");
    cycle(0, 1, '0);
    idle(2);
    expect_flag("Still EMPTY after underflow attempt", empty, 1'b1);

    $display("\n--- Test 5: Simultaneous Read/Write ---");
    for (int i = 0; i < 5; i++) cycle(1, 1, DATA_WIDTH'(i + 20));
    idle(2);

    $display("\n--- Test 6: Simultaneous R/W when FULL ---");
    for (int i = 0; i < DEPTH; i++) cycle(1, 0, DATA_WIDTH'(i + 50));
    cycle(1, 1, 8'hEE);
    idle(2);

    for (int i = 0; i < DEPTH - 1; i++) cycle(0, 1, '0);
    cycle(1, 1, 8'h77);
    idle(2);

    $display("\n--- Test 8: Pointer wrap ---");
    for (int k = 0; k < 4; k++) begin
        for (int i = 0; i < DEPTH; i++) cycle(1, 0, DATA_WIDTH'($urandom));
        for (int i = 0; i < DEPTH; i++) cycle(0, 1, '0);
    end
    idle(2);

    $display("\n--- Test 9: Random traffic ---");
    random_traffic(500, 50, 50);
    random_traffic(300, 80, 20);
    random_traffic(300, 20, 80);

    $display("\n--- Test 10: Resets in different states ---");
    // reset while full
    for (int i = 0; i < DEPTH; i++) cycle(1, 0, DATA_WIDTH'($urandom));
    @(negedge clk); w_en = 0; r_en = 0; rst_n = 0;
    repeat (2) @(negedge clk); rst_n = 1; idle(2);
    expect_flag("EMPTY after reset from FULL", empty, 1'b1);

    // reset while empty
    @(negedge clk); rst_n = 0;
    repeat (2) @(negedge clk); rst_n = 1; idle(2);

    // reset during simultaneous R/W
    for (int i = 0; i < 4; i++) cycle(1, 0, DATA_WIDTH'($urandom));
    @(negedge clk); w_en = 1; r_en = 1; rst_n = 0;
    repeat (2) @(negedge clk); rst_n = 1; w_en = 0; r_en = 0; idle(2);
    expect_flag("EMPTY after reset during R/W", empty, 1'b1);

    // repeated random resets
    repeat (12) begin
        random_traffic(10, 70, 30);
        @(negedge clk); w_en = 0; r_en = 0; rst_n = 0;
        repeat (2) @(negedge clk); rst_n = 1;
    end
    random_traffic(100, 50, 50);
    
    idle(5);

    $display("\n======== SUMMARY ========");
    $display("Accepted writes     : %0d", n_writes);
    $display("Accepted reads      : %0d", n_reads);
    $display("Simultaneous R/W    : %0d", n_simul);
    $display("Overflow attempts   : %0d", n_overflow_try);
    $display("Underflow attempts  : %0d", n_underflow_try);
    $display("Errors              : %0d", errors);
    if (errors == 0) $display("*** TEST PASSED ***");
    else             $display("*** TEST FAILED ***");
    $finish;
end

logic debug;
initial debug = $test$plusargs("DEBUG");

always @(posedge clk) if (debug) begin
    $strobe("Time=%0t | rst_n=%b w_en=%b r_en=%b din=0x%0h | full=%b empty=%b | dout=0x%0h exp=0x%0h | count=%0d model=%0d | w_ptr=%0d r_ptr=%0d",
            $time, rst_n, w_en, r_en, data_in, full, empty,
            data_out, exp_out, count, exp_q.size(), w_ptr, r_ptr);
end

initial begin
    $dumpfile("tb_sync_fifo.vcd");
    $dumpvars(0, tb_sync_fifo);
end

initial begin
    #1_000_000;
    $display("TIMEOUT");
    $fatal(1, "Simulation timed out");
end

endmodule
/* verilator coverage_on */