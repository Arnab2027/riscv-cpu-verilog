# Test program: sum 1..10, memory, ALU ops, lui/auipc, jal/jalr
        addi x1, x0, 0        # sum = 0
        addi x2, x0, 1        # i = 1
        addi x3, x0, 11       # limit = 11
loop:   add  x1, x1, x2       # sum += i
        addi x2, x2, 1        # i++
        blt  x2, x3, loop     # repeat while i < 11
        sw   x1, 0(x0)        # mem[0] = 55
        lw   x4, 0(x0)        # x4 = 55
        addi x5, x0, 7
        sub  x6, x4, x5       # 48
        slli x7, x5, 3        # 56
        xor  x8, x6, x7       # 8
        or   x9, x6, x5       # 55
        and  x10, x4, x7      # 48
        slt  x11, x5, x4      # 1
        lui  x12, 0x12345     # 0x12345000
        addi x17, x0, -16
        srai x18, x17, 2      # -4
        srli x19, x17, 28     # 15
        auipc x16, 1          # pc + 0x1000
        jal  x13, func        # call func, x13 = return address
        addi x14, x0, 99      # runs after return
        sw   x14, 4(x0)       # mem[1] = 99
done:   beq  x0, x0, done     # stop here (loop forever)
func:   addi x15, x0, 42
        jalr x0, 0(x13)       # return
