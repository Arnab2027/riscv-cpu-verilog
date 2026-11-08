// Control unit: reads the opcode and tells every other block what to do
module control (
    input      [6:0] opcode,
    input      [2:0] funct3,
    input            funct7_5,      // bit 30 of the instruction
    output reg       reg_write,
    output reg       alu_src_a,     // 0 = rs1, 1 = pc
    output reg       alu_src_b,     // 0 = rs2, 1 = immediate
    output reg       mem_write,
    output reg       branch,
    output reg       jal,
    output reg       jalr,
    output reg [1:0] wb_sel,        // 00 = ALU, 01 = memory, 10 = pc+4, 11 = immediate
    output reg [3:0] alu_ctrl
);
    localparam OP_R = 7'b0110011, OP_I = 7'b0010011, OP_LW = 7'b0000011,
               OP_SW = 7'b0100011, OP_B = 7'b1100011, OP_JAL = 7'b1101111,
               OP_JALR = 7'b1100111, OP_LUI = 7'b0110111, OP_AUIPC = 7'b0010111;

    wire is_r = (opcode == OP_R);

    // Which ALU operation does funct3 / funct7 ask for?
    reg [3:0] alu_op;
    always @(*) begin
        case (funct3)
            3'b000: alu_op = (is_r & funct7_5) ? 4'd1 : 4'd0;  // sub / add
            3'b001: alu_op = 4'd7;                             // sll
            3'b010: alu_op = 4'd5;                             // slt
            3'b011: alu_op = 4'd6;                             // sltu
            3'b100: alu_op = 4'd4;                             // xor
            3'b101: alu_op = funct7_5 ? 4'd9 : 4'd8;           // sra / srl
            3'b110: alu_op = 4'd3;                             // or
            default: alu_op = 4'd2;                            // and
        endcase
    end

    always @(*) begin
        // safe defaults
        reg_write = 0; alu_src_a = 0; alu_src_b = 0; mem_write = 0;
        branch = 0; jal = 0; jalr = 0; wb_sel = 2'b00; alu_ctrl = 4'd0;

        case (opcode)
            OP_R:     begin reg_write = 1; alu_ctrl = alu_op; end
            OP_I:     begin reg_write = 1; alu_src_b = 1; alu_ctrl = alu_op; end
            OP_LW:    begin reg_write = 1; alu_src_b = 1; wb_sel = 2'b01; end
            OP_SW:    begin alu_src_b = 1; mem_write = 1; end
            OP_B:     begin branch = 1; end
            OP_JAL:   begin reg_write = 1; jal = 1; wb_sel = 2'b10; end
            OP_JALR:  begin reg_write = 1; jalr = 1; alu_src_b = 1; wb_sel = 2'b10; end
            OP_LUI:   begin reg_write = 1; wb_sel = 2'b11; end
            OP_AUIPC: begin reg_write = 1; alu_src_a = 1; alu_src_b = 1; end
            default:  ;
        endcase
    end
endmodule