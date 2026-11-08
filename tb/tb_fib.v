`timescale 1ns/1ps
module tb_fib;
    reg clk = 0;
    reg rst = 1;
    integer k;

    riscv_cpu #(.HEX("sw/fib12.hex")) dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        repeat (3) @(posedge clk);
        #1 rst = 0;
        repeat (100) @(posedge clk);
        #1;
        $display("\n------ FIBONACCI NUMBERS STORED IN MEMORY ------");
        for (k = 0; k < 12; k = k + 1)
            $display("fib[%0d] = %0d", k, dut.u_dmem.mem[k]);
        $finish;
    end
endmodule