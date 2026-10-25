import uvm_pkg::*;
import fifo_uvm_pkg::*;

module tb_top;

logic clk = 0;
always #5 clk = ~clk;

fifo_if #(.DATA_WIDTH(8)) fifo_vif (.clk(clk));

sync_fifo #(.DEPTH(8), .DATA_WIDTH(8)) dut (
    .clk(fifo_vif.clk), .rst_n(fifo_vif.rst_n), .w_en(fifo_vif.w_en), .r_en(fifo_vif.r_en),
    .data_in(fifo_vif.data_in), .data_out(fifo_vif.data_out), .full(fifo_vif.full), .empty(fifo_vif.empty)
);

initial begin
    uvm_config_db #(virtual fifo_if)::set(
        null, "uvm_test_top", "vif", fifo_vif
    );
    run_test("fifo_test");
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
end

endmodule
