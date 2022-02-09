#!/usr/bin/python3
import os
import sys

elf_file_name = "test.elf"
sym_file_name = "test.sym"

def create_symbol_file( elf_file, sym_file ):

    try:
        cmd = "nm " + elf_file
        nm_out_lines = os.popen( cmd ).readlines()
    except:
        print ( sys.argv[0],
                ": create_symbol_file: Error executing: " , cmd , "\n" )
        sys.exit(1)

    symbols = []

    for line in nm_out_lines:
        line = line.strip()
        words = line.split(" ")
        sym_name = words[2]
        sym_addr = words[0]
        symbols.append(sym_name + " " + sym_addr + "\n")

        #if sym_name == search_sym:
        #    print "Found symbol ", sym_name, " @ ", sym_addr
        #    found = True

    try:
        sf = open(sym_file, "w")

        for sym_line in symbols:
            sf.write(sym_line)

        sf.close()
    except Exception as e:
        print ( sys.argv[0],
                ": create_symbol_file: Error writing to symbol file ",
                sym_file , " ", str(e),"\n" )
        sys.exit(1)


def main():

    if len(sys.argv) == 3:
        global elf_file_name
        global sym_file_name
        elf_file_name = sys.argv[1]
        sym_file_name = sys.argv[2]
    #print " files: ", elf_file_name, " ", sym_file_name
    create_symbol_file(elf_file_name, sym_file_name)


if __name__ == "__main__":
    main()

