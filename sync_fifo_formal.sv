module sync_fifo_formal #(parameter DEPTH=8, DATA_WIDTH=8) (
    input logic clk, rst_n,
    input logic w_en, r_en,
    input logic [DATA_WIDTH-1:0] data_in
);

logic [DATA_WIDTH-1:0] data_out;
logic full, empty;

sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n), .r_en(r_en), .w_en(w_en), .data_in(data_in),
    .data_out(data_out), .full(full), .empty(empty));

logic f_past_valid = 1'b0;
always_ff @(posedge clk) f_past_valid <= 1'b1;
always_comb if (!f_past_valid) assume(!rst_n);

logic [$clog2(DEPTH):0] f_count;
wire f_wr = w_en && (f_count != DEPTH);
wire f_rd = r_en && (f_count != 0);

always_ff @(posedge clk) begin
    if (!rst_n) f_count <= 0;
    else begin
        case ({f_wr, f_rd})
            2'b10: f_count <= f_count + 1'b1;
            2'b01: f_count <= f_count - 1'b1;
            default: f_count <= f_count;
        endcase
    end
end

always @(posedge clk) if (f_past_valid) begin
    assert(full  == (f_count == DEPTH));
    assert(empty == (f_count == 0));
    assert(!(full && empty));
    if (!$past(rst_n)) assert (data_out == 0);
    else if (!$past(f_rd)) assert (data_out == $past(data_out));
end

(* anyconst *) logic [7:0] f_idx;

logic [7:0] f_wr_cnt, f_rd_cnt;
logic [DATA_WIDTH-1:0] f_data;
logic f_seen, f_check;

always_ff @(posedge clk) begin
    f_check <= 1'b0;
    if (!rst_n) begin f_wr_cnt <= '0; f_rd_cnt <= '0; f_seen <= 1'b0; end
    else begin
        if (f_wr) begin
            f_wr_cnt <= f_wr_cnt + 1'b1;
            if (f_wr_cnt == f_idx) begin f_data <= data_in; f_seen <= 1'b1; end
        end
        if (f_rd) begin
            f_rd_cnt <= f_rd_cnt + 1'b1;
            if (f_rd_cnt == f_idx) f_check <= 1'b1;
        end
    end
end

always_ff @(posedge clk) begin
    if (f_past_valid && f_check) assert (f_seen && data_out == f_data);
    cover(full);
    cover(empty && $past(full));
    cover(f_wr && f_rd);
    cover(f_check);    
end

endmodule