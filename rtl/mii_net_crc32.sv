/*

Assert init before the first byte in the frame
assert calc and valid for each byte.

The crc_reg is constantly updated with the 32bit CRC Val
o_crc is made specifically for the toxicity of 802.3 
you can just imagine it contains a bit reversed version 
of the hightest byte of the 32bit CRC val.

Asserting data_valid without calc will cause the CRC value
to perform 8 bit left shift. (So will the o_crc). So for 802.3
just assert valid for 4 extra cycles you will get the 802.3 
crc32

*/

module mii_net_crc32(
    i_clk,
    i_reset,

    d,
    i_d_valid,
    i_calc,
    i_init,

    o_crc_reg,
    o_crc,
);

    output reg [31:0] o_crc_reg;
    output reg [7:0] o_crc;

    input wire [7:0] d;
    input wire i_calc;
    input wire i_init;
    input wire i_d_valid;
    input wire i_clk;
    input wire i_reset;

    wire [31:0] next_crc = nextCRC32_D8(ref_byte(d), o_crc_reg);

    always @(posedge i_clk)
        begin
// 802.3 initial value 0xFF.....
            if (i_reset || i_init) begin
                o_crc_reg <= 32'hFFFFFFFF;
                o_crc <= 8'hFF;
            end

            else if (i_calc && i_d_valid) begin
                // Calculated next CRC

                //  table[(crc ^ msg[i]) & 0xff] ^ (crc >> 8)
                o_crc_reg <= next_crc;
                // Thanks 802.3 I love this reversed order :) Works well with serial CRC
                // but I am on MAC layer.
                o_crc <= ~ref_byte(next_crc[7:0]);
            end
            else if (~i_calc & i_d_valid) begin
                // Just assert d_valid without calc you can slowly get all the values (over 4 cycles)
                o_crc_reg <= {o_crc_reg[23:0], 8'hFF};
                // Reversed shifted most siginificant (match the o_crc_reg above)
                o_crc <= ~ref_byte(o_crc_reg[31:24]);
            end
        end

    function [31:0] nextCRC32_D8;

        input [7:0] Data;
        input [31:0] crc;
        reg [7:0] d;
        reg [31:0] c;
        reg [31:0] newcrc;
        begin
            d = Data;
            c = crc;

            newcrc[0] = d[6] ^ d[0] ^ c[24] ^ c[30];
            newcrc[1] = d[7] ^ d[6] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[30] ^ c[31];
            newcrc[2] = d[7] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[26] ^ c[30] ^ c[31];
            newcrc[3] = d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[27] ^ c[31];
            newcrc[4] = d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[28] ^ c[30];
            newcrc[5] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
            newcrc[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
            newcrc[7] = d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[31];
            newcrc[8] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
            newcrc[9] = d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29];
            newcrc[10] = d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[2] ^ c[24] ^ c[26] ^ c[27] ^ c[29];
            newcrc[11] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[3] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
            newcrc[12] = d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[4] ^ c[24] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30];
            newcrc[13] = d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ c[5] ^ c[25] ^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31];
            newcrc[14] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ c[6] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ c[31];
            newcrc[15] = d[7] ^ d[5] ^ d[4] ^ d[3] ^ c[7] ^ c[27] ^ c[28] ^ c[29] ^ c[31];
            newcrc[16] = d[5] ^ d[4] ^ d[0] ^ c[8] ^ c[24] ^ c[28] ^ c[29];
            newcrc[17] = d[6] ^ d[5] ^ d[1] ^ c[9] ^ c[25] ^ c[29] ^ c[30];
            newcrc[18] = d[7] ^ d[6] ^ d[2] ^ c[10] ^ c[26] ^ c[30] ^ c[31];
            newcrc[19] = d[7] ^ d[3] ^ c[11] ^ c[27] ^ c[31];
            newcrc[20] = d[4] ^ c[12] ^ c[28];
            newcrc[21] = d[5] ^ c[13] ^ c[29];
            newcrc[22] = d[0] ^ c[14] ^ c[24];
            newcrc[23] = d[6] ^ d[1] ^ d[0] ^ c[15] ^ c[24] ^ c[25] ^ c[30];
            newcrc[24] = d[7] ^ d[2] ^ d[1] ^ c[16] ^ c[25] ^ c[26] ^ c[31];
            newcrc[25] = d[3] ^ d[2] ^ c[17] ^ c[26] ^ c[27];
            newcrc[26] = d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[18] ^ c[24] ^ c[27] ^ c[28] ^ c[30];
            newcrc[27] = d[7] ^ d[5] ^ d[4] ^ d[1] ^ c[19] ^ c[25] ^ c[28] ^ c[29] ^ c[31];
            newcrc[28] = d[6] ^ d[5] ^ d[2] ^ c[20] ^ c[26] ^ c[29] ^ c[30];
            newcrc[29] = d[7] ^ d[6] ^ d[3] ^ c[21] ^ c[27] ^ c[30] ^ c[31];
            newcrc[30] = d[7] ^ d[4] ^ c[22] ^ c[28] ^ c[31];
            newcrc[31] = d[5] ^ c[23] ^ c[29];
            nextCRC32_D8 = newcrc;
        end
    endfunction

    function [7:0] ref_byte;
        input [7:0] data;
        begin
			ref_byte = {data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]};
        end
    endfunction : ref_byte

endmodule: mii_net_crc32

