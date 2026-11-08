#!/usr/bin/env python3
"""Reference model: runs program.hex like the CPU would, prints expected results."""
import sys
M = 0xFFFFFFFF
def sx(v, bits): return v - (1<<bits) if v >> (bits-1) else v
def run(hexfile, cycles=200):
    imem = [int(l,16) for l in open(hexfile) if l.strip()]
    x = [0]*32; mem = [0]*256; pc = 0
    for _ in range(cycles):
        i = imem[pc>>2] if (pc>>2) < len(imem) else 0x13
        op=i&0x7F; rd=i>>7&31; f3=i>>12&7; r1=i>>15&31; r2=i>>20&31; f7=i>>25
        a, b = x[r1], x[r2]; npc = pc+4; w = None
        immI = sx(i>>20,12); immS = sx((i>>25)<<5|(i>>7&31),12)
        immB = sx((i>>31&1)<<12|(i>>7&1)<<11|(i>>25&0x3F)<<5|(i>>8&0xF)<<1,13)
        immJ = sx((i>>31&1)<<20|(i>>12&0xFF)<<12|(i>>20&1)<<11|(i>>21&0x3FF)<<1,21)
        def alu(f3,f7,a,b,sub_ok):
            if f3==0: return (a-b)&M if (sub_ok and f7==0x20) else (a+b)&M
            if f3==1: return (a<<(b&31))&M
            if f3==2: return int(sx(a,32)<sx(b,32))
            if f3==3: return int(a<b)
            if f3==4: return a^b
            if f3==5: return (sx(a,32)>>(b&31))&M if f7==0x20 else a>>(b&31)
            if f3==6: return a|b
            return a&b
        if op==0x33: w = alu(f3,f7,a,b,True)
        elif op==0x13: w = alu(f3,f7,a,immI&M if f3 not in (1,5) else immI&31,False)
        elif op==0x03: w = mem[((a+immI)&M)>>2]
        elif op==0x23: mem[((a+immS)&M)>>2] = b
        elif op==0x63:
            t = {0:a==b,1:a!=b,4:sx(a,32)<sx(b,32),5:sx(a,32)>=sx(b,32),6:a<b,7:a>=b}[f3]
            if t: npc = (pc+immB)&M
        elif op==0x6F: w = pc+4; npc = (pc+immJ)&M
        elif op==0x67: w = pc+4; npc = (a+immI)&M&~1
        elif op==0x37: w = i&0xFFFFF000
        elif op==0x17: w = (pc+(i&0xFFFFF000))&M
        if w is not None and rd: x[rd] = w & M
        pc = npc
    return x, mem
if __name__ == '__main__':
    x, mem = run(sys.argv[1])
    for n in range(1,20): print('x%-2d = 0x%08x (%d)' % (n, x[n], sx(x[n],32)))
    print('mem[0] =', mem[0], ' mem[1] =', mem[1])
