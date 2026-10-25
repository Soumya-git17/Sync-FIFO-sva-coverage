interface fifo_if #(
    parameter int DATA_WIDTH = 8
)(
    input logic clk
);

logic rst_n, w_en, r_en;
logic [DATA_WIDTH-1:0] data_in;
logic [DATA_WIDTH-1:0] data_out;
logic full, empty;

endinterface