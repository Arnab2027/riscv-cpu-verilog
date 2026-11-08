// Top level: single-cycle RV32I CPU
module riscv_cpu #(
    parameter HEX = "sw/program.hex"
)(
    input clk,
    input rst
);
    // ---------------- wires ----------------
    reg  [31:0] pc;
    wire [31:0] pc_plus4, pc_target, pc_next;
    wire [31:0] instr, imm;
    wire [31:0] rs1_data, rs2_data, alu_a, alu_b, alu_y, dmem_rdata;
    reg  [31:0] wb_data;

    wire        reg_write, alu_src_a, alu_src_b, mem_write, branch, jal, jalr;
    wire [1:0]  wb_sel;
    wire [3:0]  alu_ctrl;
    wire        taken;

    // ---------------- fetch ----------------
    always @(posedge clk)
        if (rst) pc <= 32'd0;
        else     pc <= pc_next;

    imem #(.HEX(HEX)) u_imem (.addr(pc), .instr(instr));

    // ---------------- decode ----------------
    control u_control (
        .opcode(instr[6:0]), .funct3(instr[14:12]), .funct7_5(instr[30]),
        .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_write(mem_write), .branch(branch), .jal(jal), .jalr(jalr),
        .wb_sel(wb_sel), .alu_ctrl(alu_ctrl)
    );

    imm_gen u_imm_gen (.instr(instr), .imm(imm));

    regfile u_regfile (
        .clk(clk), .we(reg_write),
        .rs1(instr[19:15]), .rs2(instr[24:20]), .rd(instr[11:7]),
        .wd(wb_data), .rd1(rs1_data), .rd2(rs2_data)
    );

    // ---------------- execute ----------------
    assign alu_a = alu_src_a ? pc  : rs1_data;
    assign alu_b = alu_src_b ? imm : rs2_data;

    alu u_alu (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .y(alu_y));

    branch_unit u_branch (.a(rs1_data), .b(rs2_data), .funct3(instr[14:12]), .taken(taken));

    // ---------------- memory ----------------
    dmem u_dmem (
        .clk(clk), .we(mem_write), .addr(alu_y),
        .wdata(rs2_data), .rdata(dmem_rdata)
    );

    // ---------------- write back ----------------
    always @(*) begin
        case (wb_sel)
            2'b00:   wb_data = alu_y;
            2'b01:   wb_data = dmem_rdata;
            2'b10:   wb_data = pc_plus4;
            default: wb_data = imm;          // lui
        endcase
    end

    // ---------------- next pc ----------------
    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + imm;
    assign pc_next   = jalr                      ? (alu_y & 32'hFFFFFFFE) :
                       (jal | (branch & taken))  ? pc_target :
                                                   pc_plus4;
endmodule
