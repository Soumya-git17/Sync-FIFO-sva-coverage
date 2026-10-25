module sync_fifo #(parameter DEPTH=8, DATA_WIDTH=8) (
    input  logic clk, rst_n,
    input  logic w_en, r_en,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic full, empty
);

initial assert (DEPTH >= 2 && (DEPTH & (DEPTH-1)) == 0);

logic [$clog2(DEPTH)-1:0] w_ptr, r_ptr;
logic [DATA_WIDTH-1:0] fifo[0:DEPTH-1];
logic [$clog2(DEPTH):0] count;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        w_ptr <= 0; r_ptr <= 0;
        data_out <= 0;
        count <= 0;
    end
    else begin
        if(w_en && (count < DEPTH))begin
            fifo[w_ptr] <= data_in;
            w_ptr <= w_ptr + 1;
        end
        if(r_en && (count > 0)) begin
            data_out <= fifo[r_ptr];
            r_ptr <= r_ptr + 1;
        end
        unique case ({w_en && (count < DEPTH), r_en && (count > 0)})
            2'b10: count <= count + 1;
            2'b01: count <= count - 1;
            default: count <= count;
        endcase
    end
end

assign full  = (count == DEPTH);
assign empty = (count == 0);

endmodule
