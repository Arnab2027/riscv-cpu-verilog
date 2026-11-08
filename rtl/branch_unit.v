// Branch unit: compares rs1 and rs2 and says if the branch is taken
module branch_unit (
    input  [31:0] a, b,
    input  [2:0]  funct3,
    output reg    taken
);
    wire eq  = (a == b);
    wire lt  = ($signed(a) < $signed(b));
    wire ltu = (a < b);

    always @(*) begin
        case (funct3)
            3'b000:  taken = eq;     // beq
            3'b001:  taken = ~eq;    // bne
            3'b100:  taken = lt;     // blt
            3'b101:  taken = ~lt;    // bge
            3'b110:  taken = ltu;    // bltu
            3'b111:  taken = ~ltu;   // bgeu
            default: taken = 1'b0;
        endcase
    end
endmodule
