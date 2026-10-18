/* verilator coverage_off */
module sync_fifo_assertions #(
    parameter DEPTH = 8,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst_n,
    input logic w_en,
    input logic r_en,
    input logic full,
    input logic empty,
    input logic [$clog2(DEPTH):0] count,
    input logic [$clog2(DEPTH)-1:0] w_ptr,
    input logic [$clog2(DEPTH)-1:0] r_ptr,
    input logic [DATA_WIDTH-1:0] data_out
);

logic past_valid;
localparam PW = $clog2(DEPTH);

always_ff @(posedge clk) begin
    if (!rst_n) past_valid <= 1'b0;
    else past_valid <= 1'b1;
end

wire do_wr = w_en && !full;
wire do_rd = r_en && !empty;

wire [PW-1:0] w_ptr_nxt = (w_ptr == PW'(DEPTH-1)) ? '0 : w_ptr + 1'b1;
wire [PW-1:0] r_ptr_nxt = (r_ptr == PW'(DEPTH-1)) ? '0 : r_ptr + 1'b1;


assert property (@(posedge clk)
    !rst_n |=> (count == 0 && w_ptr == 0 && r_ptr == 0 && data_out == 0)); 


assert property (@(posedge clk) disable iff (!rst_n) count <= DEPTH);
assert property (@(posedge clk) disable iff (!rst_n) empty == (count == 0));
assert property (@(posedge clk) disable iff (!rst_n) full == (count == DEPTH));
assert property (@(posedge clk) disable iff (!rst_n) !(full && empty));


assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && do_wr && do_rd |=> count == $past(count));
assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && do_wr && !(do_rd) |=> count == $past(count) + 1'b1);
assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && !(do_wr) && do_rd |=> count == $past(count) - 1'b1);
assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && !(do_wr) && !(do_rd) |=> count == $past(count));


assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && do_wr |=> w_ptr == $past(w_ptr_nxt));
assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && do_rd |=> r_ptr == $past(r_ptr_nxt));
assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && !(do_wr) |=> w_ptr == $past(w_ptr));
assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && !(do_rd) |=> r_ptr == $past(r_ptr));


assert property (@(posedge clk) disable iff (!rst_n)
    past_valid && !(do_rd) |=> $stable(data_out));

cover property (@(posedge clk) disable iff (!rst_n) past_valid && $changed(count));
cover property (@(posedge clk) disable iff (!rst_n) $rose(full));
cover property (@(posedge clk) disable iff (!rst_n) $fell(empty));

cover property (@(posedge clk) disable iff (!rst_n)
    past_valid && w_en && full);
cover property (@(posedge clk) disable iff (!rst_n)
    past_valid && r_en && empty);

assert property (@(posedge clk) disable iff (!rst_n)
    (w_ptr == r_ptr) |-> (full || empty));
assert property (@(posedge clk) disable iff (!rst_n)
    full |-> (w_ptr == r_ptr));
assert property (@(posedge clk) disable iff (!rst_n)
    empty |-> (w_ptr == r_ptr));

wire [PW-1:0] ptr_diff = w_ptr - r_ptr;
assert property (@(posedge clk) disable iff (!rst_n)
    count[PW-1:0] == ptr_diff);

endmodule
/* verilator coverage_on */
