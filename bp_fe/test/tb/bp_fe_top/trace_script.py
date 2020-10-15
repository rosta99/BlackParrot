#!/bin/usr/python

import sys, getopt
from trace_gen import TraceGen

def main():
  
  tracer = TraceGen(39, 32)
  filepath = sys.argv[1]

  filename = filepath + "test_linear_fetch.tr"
  file = open(filename, "w")

  file.write(tracer.print_header())
  
  file.write(tracer.print_comment("Fetch linearly"))
  for i in range(0, 64, 4):
    temp_vaddr = 0x80000000 + i
    temp_instr = i
    file.write(tracer.recv_pc_instr(temp_vaddr, temp_instr))
    
  file.write(tracer.test_finish())
  file.close()

  filename = filepath + "test_redirect.tr"
  file = open(filename, "w")

  file.write(tracer.print_header())

  file.write(tracer.print_comment("Fetch, redirecting to the beginning a few times"))
  for i in range(0, 64, 4):
    temp_vaddr = 0x80000000 + i
    temp_instr = i
    file.write(tracer.recv_pc_instr(temp_vaddr, temp_instr))
  file.write(tracer.send_redirect(0x80000000))
   
  for i in range(0, 64, 4):
    temp_vaddr = 0x80000000 + i
    temp_instr = i
    file.write(tracer.recv_pc_instr(temp_vaddr, temp_instr))
  file.write(tracer.send_redirect(0x80000000))

  for i in range(0, 64, 4):
    temp_vaddr = 0x80000000 + i
    temp_instr = i
    file.write(tracer.recv_pc_instr(temp_vaddr, temp_instr))

  file.write(tracer.test_finish())
  file.close()


if __name__ == "__main__":
  main()
  
