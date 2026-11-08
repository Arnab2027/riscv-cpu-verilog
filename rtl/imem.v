// Instruction memory (read only). Loaded from a hex file.
module imem #(
    parameter DEPTH = 256,
    parameter HEX   = "sw/program.hex"
)(
    input  [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'h00000013; // nop (addi x0,x0,0)
        $readmemh(HEX, mem);
    end
    assign instr = mem[addr[9:2]];   // word address
endmodule
