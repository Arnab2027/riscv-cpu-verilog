// Register file: 32 registers, each 32 bits. x0 is always 0.
module regfile (
    input         clk,
    input         we,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wd,
    output [31:0] rd1, rd2
);
    reg [31:0] regs [0:31];
    integer i;
    initial for (i = 0; i < 32; i = i + 1) regs[i] = 32'd0;

    // write on the clock edge (never write x0)
    always @(posedge clk)
        if (we && rd != 5'd0) regs[rd] <= wd;

    // read without waiting for the clock
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
endmodule
