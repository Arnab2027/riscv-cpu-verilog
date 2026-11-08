// Data memory. Word access only (lw / sw).
module dmem #(
    parameter DEPTH = 256
)(
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;
    initial for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'd0;

    always @(posedge clk)
        if (we) mem[addr[9:2]] <= wdata;

    assign rdata = mem[addr[9:2]];
endmodule
