#!/usr/bin/env python3
"""Tiny RV32I assembler. Usage: python3 sw/assembler.py sw/program.asm sw/program.hex"""
import re, sys

R = {'add':(0,0),'sub':(0,0x20),'sll':(1,0),'slt':(2,0),'sltu':(3,0),
     'xor':(4,0),'srl':(5,0),'sra':(5,0x20),'or':(6,0),'and':(7,0)}
I = {'addi':0,'slti':2,'sltiu':3,'xori':4,'ori':6,'andi':7}
SH = {'slli':(1,0),'srli':(5,0),'srai':(5,0x20)}
B = {'beq':0,'bne':1,'blt':4,'bge':5,'bltu':6,'bgeu':7}

def reg(s):
    m = re.fullmatch(r'x(\d+)', s.strip())
    if not m or int(m.group(1)) > 31: raise ValueError('bad register ' + s)
    return int(m.group(1))

def num(s): return int(s.strip(), 0)

def assemble(lines):
    labels, prog, pc = {}, [], 0
    for ln in lines:                       # pass 1: find labels
        ln = ln.split('#')[0].strip()
        if not ln: continue
        while ':' in ln:
            lab, ln = ln.split(':', 1); labels[lab.strip()] = pc; ln = ln.strip()
        if ln: prog.append((pc, ln)); pc += 4
    words = []
    for pc, ln in prog:                    # pass 2: encode
        op, _, rest = ln.partition(' ')
        a = [x.strip() for x in rest.split(',')] if rest else []
        if op in R:
            f3, f7 = R[op]; w = f7<<25 | reg(a[2])<<20 | reg(a[1])<<15 | f3<<12 | reg(a[0])<<7 | 0x33
        elif op in I:
            w = (num(a[2])&0xFFF)<<20 | reg(a[1])<<15 | I[op]<<12 | reg(a[0])<<7 | 0x13
        elif op in SH:
            f3, f7 = SH[op]; w = f7<<25 | (num(a[2])&31)<<20 | reg(a[1])<<15 | f3<<12 | reg(a[0])<<7 | 0x13
        elif op == 'lw':
            m = re.fullmatch(r'(-?\w+)\((x\d+)\)', a[1])
            w = (num(m.group(1))&0xFFF)<<20 | reg(m.group(2))<<15 | 2<<12 | reg(a[0])<<7 | 0x03
        elif op == 'sw':
            m = re.fullmatch(r'(-?\w+)\((x\d+)\)', a[1]); imm = num(m.group(1))&0xFFF
            w = (imm>>5)<<25 | reg(a[0])<<20 | reg(m.group(2))<<15 | 2<<12 | (imm&31)<<7 | 0x23
        elif op in B:
            off = (labels[a[2]] - pc) & 0x1FFF
            w = (off>>12&1)<<31 | (off>>5&0x3F)<<25 | reg(a[1])<<20 | reg(a[0])<<15 | B[op]<<12 | (off>>1&0xF)<<8 | (off>>11&1)<<7 | 0x63
        elif op == 'jal':
            off = (labels[a[1]] - pc) & 0x1FFFFF
            w = (off>>20&1)<<31 | (off>>1&0x3FF)<<21 | (off>>11&1)<<20 | (off>>12&0xFF)<<12 | reg(a[0])<<7 | 0x6F
        elif op == 'jalr':
            m = re.fullmatch(r'(-?\w+)\((x\d+)\)', a[1])
            w = (num(m.group(1))&0xFFF)<<20 | reg(m.group(2))<<15 | 0<<12 | reg(a[0])<<7 | 0x67
        elif op in ('lui','auipc'):
            w = (num(a[1])&0xFFFFF)<<12 | reg(a[0])<<7 | (0x37 if op=='lui' else 0x17)
        else:
            raise ValueError('unknown instruction: ' + ln)
        words.append(w & 0xFFFFFFFF)
    return words

if __name__ == '__main__':
    words = assemble(open(sys.argv[1]).read().splitlines())
    with open(sys.argv[2], 'w') as f:
        for w in words: f.write('%08x\n' % w)
    print('Assembled %d instructions -> %s' % (len(words), sys.argv[2]))
