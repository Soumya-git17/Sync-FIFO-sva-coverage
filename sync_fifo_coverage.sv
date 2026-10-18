module sync_fifo_coverage #(parameter DEPTH = 8)(
    input logic clk,
    input logic rst_n,
    input logic [$clog2(DEPTH):0] count,
    input logic w_en,
    input logic r_en,
    input logic full,
    input logic empty,
    input logic [$clog2(DEPTH)-1:0] w_ptr,
    input logic [$clog2(DEPTH)-1:0] r_ptr
);

wire do_wr = w_en && !full;
wire do_rd = r_en && !empty;


covergroup fifo_cg @(posedge clk);
    cp_count: coverpoint count iff (rst_n) {
        bins empty_bin = {0};
        bins partial_bin = {[1:DEPTH-1]};
        bins full_bin = {DEPTH};
        bins empty_to_one = (0 => 1);
        bins one_to_empty = (1 => 0);
        bins almost_full_to_full = (7 => 8);
        bins full_to_almost_full = (8 => 7);
    }
    cp_write_req: coverpoint w_en iff (rst_n);
    cp_read_req:  coverpoint r_en iff (rst_n);

    cp_write: coverpoint do_wr iff (rst_n);
    cp_read:  coverpoint do_rd iff (rst_n);
    
    count_x_write_req: cross cp_count, cp_write_req;
    count_x_read_req:  cross cp_count, cp_read_req;
    
    // count_x_write: cross cp_count, cp_write;
    // count_x_read:  cross cp_count, cp_read;
    // count_x_ops:   cross cp_count, cp_read, cp_write;

    request_ops: cross cp_write_req, cp_read_req;
    count_x_requests: cross cp_count, cp_read_req, cp_write_req;

    accepted_ops: cross cp_read, cp_write;

    cp_w_ptr:  coverpoint w_ptr iff (rst_n){ bins wrap = (7 => 0); }
    cp_r_ptr:  coverpoint r_ptr iff (rst_n){ bins wrap = (7 => 0); }
endgroup

covergroup reset_cg @(posedge clk);
    cp_reset: coverpoint rst_n {
        bins reset_active = {0};
        bins reset_released = (0 => 1);
    }
endgroup

fifo_cg cg = new();
reset_cg rcg = new();

endmodule
