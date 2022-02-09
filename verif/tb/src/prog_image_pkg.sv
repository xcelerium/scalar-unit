package prog_image_pkg;

    function automatic void read_sym_file ( string sym_file, ref bit [31:0] syms[string]);

        int debug = 0;

        integer fid_sym;
        string sname;
        bit [31:0] saddr;

        if (debug) $display("Starting to read symbols file");

        fid_sym = $fopen( sym_file, "r");
        if ( fid_sym == 0 ) begin
            $display("Error opening symbols file");
        end

        while ( $fscanf(fid_sym, "%s %x", sname, saddr) != 0 &&
                !$feof(fid_sym)) begin
            syms[sname] = saddr;
        end

        $fclose(fid_sym);
        if (debug) $display("Finished reading sym file");

    endfunction: read_sym_file

    function automatic void read_hex_file ( string hex_file, ref bit [7:0] pimg[int]);

        int debug = 0;

        integer fid_hex;
        string astring, addr_string;
        bit [31:0] addr;
        bit [7:0] data;

        if (debug) $display("Starting to read hex file");

        fid_hex = $fopen( hex_file, "r");
        if ( fid_hex == 0 ) begin
            $display("Error opening hex file");
        end

        addr = 'b0;

        while ( $fscanf(fid_hex, "%s", astring) != 0 && !$feof(fid_hex)) begin
            //$display("a string: %s", astring);
            if ( astring[0] == "@" && astring.len() > 1 ) begin
                // Extract Address
                addr_string = astring.substr(1, astring.len()-1);
                addr = addr_string.atohex();
                if (debug) $display("address update: %x", addr);
            end
            else begin
                data = astring.atohex();
                pimg[addr] = data;
                //$display("write: %8.8x = %2.2x", addr, data);
                addr++;
            end

        end
        $fclose(fid_hex);
        if (debug) $display("Finished reading hex file");

    endfunction: read_hex_file

endpackage: prog_image_pkg

