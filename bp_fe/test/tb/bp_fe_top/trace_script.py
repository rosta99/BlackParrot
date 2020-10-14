#!/bin/usr/python

import sys, getopt
from trace_gen import TraceGen

def main():
  
  tracer = TraceGen(39, 32)
  filepath = sys.argv[1]

  filename = filepath + "test_linear_fetch.tr"
  file = open(filename, "w")

  file.write(tracer.print_header())
  
  file.write(tracer.print_comment("Fetch from address - 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60"))
  for i in range(0, 64, 4):
    temp_vaddr = 0x80000000 + i
    temp_instr = i
    file.write(tracer.recv_pc_instr(temp_vaddr, temp_instr))
    
  file.write(tracer.test_finish())
  file.close()

if __name__ == "__main__":
  main()
  
