        addi x1, x0, 0        # a = 0
        addi x2, x0, 1        # b = 1
        addi x3, x0, 0        # address = 0
        addi x4, x0, 48       # stop at address 48 (12 words x 4 bytes)
loop:   sw   x1, 0(x3)        # mem[address] = a
        add  x5, x1, x2       # next = a + b
        addi x1, x2, 0        # a = b
        addi x2, x5, 0        # b = next
        addi x3, x3, 4        # address = address + 4
        blt  x3, x4, loop     # if address < 48, go back to loop
done:   beq  x0, x0, done     # stop here forever