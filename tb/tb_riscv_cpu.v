`timescale 1ns/1ps
// Self-checking testbench for the RV32I CPU
module tb_riscv_cpu;
    reg clk = 0;
    reg rst = 1;
    integer errors = 0;

    riscv_cpu #(.HEX("sw/program.hex")) dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;                       // 100 MHz clock

    // print one line per instruction (trace)
    always @(posedge clk) if (!rst)
        $display("t=%0t  pc=0x%08h  instr=0x%08h  x1=%0d", $time, dut.pc, dut.instr, dut.u_regfile.regs[1]);

    task check_reg(input integer n, input [31:0] expected);
        begin
            if (dut.u_regfile.regs[n] !== expected) begin
                $display("FAIL: x%0d = 0x%08h, expected 0x%08h", n, dut.u_regfile.regs[n], expected);
                errors = errors + 1;
            end else
                $display("PASS: x%0d = 0x%08h", n, expected);
        end
    endtask

    task check_mem(input integer idx, input [31:0] expected);
        begin
            if (dut.u_dmem.mem[idx] !== expected) begin
                $display("FAIL: mem[%0d] = 0x%08h, expected 0x%08h", idx, dut.u_dmem.mem[idx], expected);
                errors = errors + 1;
            end else
                $display("PASS: mem[%0d] = 0x%08h", idx, expected);
        end
    endtask

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, tb_riscv_cpu);

        repeat (3) @(posedge clk);
        #1 rst = 0;                              // release reset
        repeat (100) @(posedge clk);             // run the program
        #1;

        $display("\n------ CHECKING RESULTS ------");
        check_reg(1,  32'd55);          // sum 1..10
        check_reg(2,  32'd11);
        check_reg(4,  32'd55);          // lw result
        check_reg(5,  32'd7);
        check_reg(6,  32'd48);          // sub
        check_reg(7,  32'd56);          // slli
        check_reg(8,  32'd8);           // xor
        check_reg(9,  32'd55);          // or
        check_reg(10, 32'd48);          // and
        check_reg(11, 32'd1);           // slt
        check_reg(12, 32'h12345000);    // lui
        check_reg(13, 32'd84);          // jal return address
        check_reg(14, 32'd99);          // code after return
        check_reg(15, 32'd42);          // code inside function
        check_reg(16, 32'h0000104C);    // auipc
        check_reg(17, 32'hFFFFFFF0);
        check_reg(18, 32'hFFFFFFFC);    // srai
        check_reg(19, 32'd15);          // srli
        check_reg(0,  32'd0);           // x0 must stay zero
        check_mem(0,  32'd55);          // sw
        check_mem(1,  32'd99);

        if (errors == 0) $display("\n*** ALL TESTS PASSED ***");
        else             $display("\n*** %0d TEST(S) FAILED ***", errors);
        $finish;
    end
endmodule
