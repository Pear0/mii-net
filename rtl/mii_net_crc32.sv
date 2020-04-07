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

    i_d,
    i_d_valid,
    i_calc,
    i_init,

    o_crc_reg, 
    o_crc,
);

output reg [31:0] o_crc_reg;
output reg [7:0]  o_crc;

input  wire [7:0]  d;
input  wire        i_calc;
input  wire    i_init;
input  wire   i_d_valid;
input  wire   i_clk;
input  wire   i_reset;

wire   [31:0] next_crc;

 
always @ (posedge i_clk)
begin
// 802.3 initial value 0xFF.....
   if (i_reset || i_init) begin
      o_crc_reg <= 32'hFFFFFFFF;
      o_crc     <= 8'hFF;
   end

   else if (i_calc && i_d_valid) begin
        // Calculated next CRC
      o_crc_reg <= next_crc;
      // Thanks 802.3 I love this reversed order :) Works well with serial CRC
      // but I am on MAC layer.
      o_crc     <= ~{next_crc[24], next_crc[25], next_crc[26], next_crc[27],
                   next_crc[28], next_crc[29], next_crc[30], next_crc[31]};
   end
   
   else if (~i_calc & i_d_valid) begin
        // Just assert d_valid without calc you can slowly get all the values (over 4 cycles)
        o_crc_reg <=  {crc_reg[23:0], 8'hFF};
        // Reversed shifted most siginificant (match the o_crc_reg above)
        o_crc     <= ~{o_crc_reg[16], o_crc_reg[17], o_crc_reg[18], o_crc_reg[19],
                    o_crc_reg[20], o_crc_reg[21], o_crc_reg[22], o_crc_reg[23]};
   end
end

// modular 1 long divison (CRC Edition)

assign next_crc[0] = o_crc_reg[30] ^ d[1] ^ o_crc_reg[24] ^ d[7];
assign next_crc[1] = d[6] ^ d[7] ^ d[0] ^ o_crc_reg[30] ^ o_crc_reg[31] ^ d[1] ^ o_crc_reg[24] ^ o_crc_reg[25];
assign next_crc[2] = o_crc_reg[26] ^ d[5] ^ d[6] ^ d[7] ^ o_crc_reg[30] ^ d[0] ^ d[1] ^ o_crc_reg[31] ^ o_crc_reg[24] ^ o_crc_reg[25];
assign next_crc[3] = d[4] ^ o_crc_reg[26] ^ d[5] ^ o_crc_reg[27] ^ d[6] ^ d[0] ^ o_crc_reg[31] ^ o_crc_reg[25];
assign next_crc[4] = d[4] ^ o_crc_reg[26] ^ d[5] ^ o_crc_reg[27] ^ o_crc_reg[28] ^ d[7] ^ o_crc_reg[30] ^ d[1] ^ o_crc_reg[24] ^ d[3];
assign next_crc[5] = d[4] ^ o_crc_reg[27] ^ d[6] ^ o_crc_reg[28] ^ d[7] ^ o_crc_reg[29] ^ o_crc_reg[30] ^ d[0] ^ d[1] ^ o_crc_reg[31] ^ d[2] ^ o_crc_reg[24] ^ d[3] ^ o_crc_reg[25];
assign next_crc[6] = o_crc_reg[26] ^ d[5] ^ d[6] ^ o_crc_reg[28] ^ o_crc_reg[29] ^ d[0] ^ o_crc_reg[30] ^ o_crc_reg[31] ^ d[1] ^ d[2] ^ d[3] ^ o_crc_reg[25];
assign next_crc[7] = d[4] ^ o_crc_reg[26] ^ d[5] ^ o_crc_reg[27] ^ d[7] ^ o_crc_reg[29] ^ d[0] ^ o_crc_reg[31] ^ d[2] ^ o_crc_reg[24];
assign next_crc[8] = d[4] ^ o_crc_reg[27] ^ d[6] ^ o_crc_reg[28] ^ d[7] ^ o_crc_reg[24] ^ o_crc_reg[0] ^ d[3] ^ o_crc_reg[25];
assign next_crc[9] = o_crc_reg[26] ^ d[5] ^ d[6] ^ o_crc_reg[28] ^ o_crc_reg[29] ^ d[2] ^ d[3] ^ o_crc_reg[25] ^ o_crc_reg[1];
assign next_crc[10] = d[4] ^ o_crc_reg[26] ^ o_crc_reg[2] ^ d[5] ^ o_crc_reg[27] ^ d[7] ^ o_crc_reg[29] ^ d[2] ^ o_crc_reg[24];
assign next_crc[11] = d[4] ^ o_crc_reg[27] ^ d[6] ^ o_crc_reg[3] ^ o_crc_reg[28] ^ d[7] ^ o_crc_reg[24] ^ d[3] ^ o_crc_reg[25];
assign next_crc[12] = o_crc_reg[26] ^ d[5] ^ d[6] ^ o_crc_reg[28] ^ d[7] ^ o_crc_reg[4] ^ o_crc_reg[29] ^ o_crc_reg[30] ^ d[1] ^ d[2] ^ o_crc_reg[24] ^ d[3] ^ o_crc_reg[25];
assign next_crc[13] = d[4] ^ o_crc_reg[26] ^ d[5] ^ o_crc_reg[27] ^ d[6] ^ o_crc_reg[29] ^ d[0] ^ o_crc_reg[30] ^ o_crc_reg[5] ^ o_crc_reg[31] ^ d[1] ^ d[2] ^ o_crc_reg[25];
assign next_crc[14] = d[4] ^ o_crc_reg[26] ^ d[5] ^ o_crc_reg[27] ^ o_crc_reg[28] ^ o_crc_reg[30] ^ d[0] ^ d[1] ^ o_crc_reg[31] ^ o_crc_reg[6] ^ d[3];
assign next_crc[15] = d[4] ^ o_crc_reg[27] ^ o_crc_reg[28] ^ o_crc_reg[29] ^ d[0] ^ o_crc_reg[31] ^ d[2] ^ o_crc_reg[7] ^ d[3];
assign next_crc[16] = o_crc_reg[28] ^ d[7] ^ o_crc_reg[29] ^ d[2] ^ o_crc_reg[24] ^ d[3] ^ o_crc_reg[8];
assign next_crc[17] = o_crc_reg[9] ^ d[6] ^ o_crc_reg[29] ^ o_crc_reg[30] ^ d[1] ^ d[2] ^ o_crc_reg[25];
assign next_crc[18] = o_crc_reg[26] ^ d[5] ^ o_crc_reg[10] ^ o_crc_reg[30] ^ d[0] ^ d[1] ^ o_crc_reg[31];
assign next_crc[19] = d[4] ^ o_crc_reg[27] ^ o_crc_reg[11] ^ d[0] ^ o_crc_reg[31];
assign next_crc[20] = o_crc_reg[28] ^ o_crc_reg[12] ^ d[3];
assign next_crc[21] = o_crc_reg[29] ^ o_crc_reg[13] ^ d[2];
assign next_crc[22] = d[7] ^ o_crc_reg[14] ^ o_crc_reg[24];
assign next_crc[23] = d[6] ^ d[7] ^ o_crc_reg[30] ^ d[1] ^ o_crc_reg[15] ^ o_crc_reg[24] ^ o_crc_reg[25];
assign next_crc[24] = o_crc_reg[26] ^ d[5] ^ d[6] ^ d[0] ^ o_crc_reg[31] ^ o_crc_reg[16] ^ o_crc_reg[25];
assign next_crc[25] = d[4] ^ o_crc_reg[17] ^ o_crc_reg[26] ^ d[5] ^ o_crc_reg[27];
assign next_crc[26] = d[4] ^ o_crc_reg[18] ^ o_crc_reg[27] ^ o_crc_reg[28] ^ d[7] ^ o_crc_reg[30] ^ d[1] ^ o_crc_reg[24] ^ d[3];
assign next_crc[27] = d[6] ^ o_crc_reg[19] ^ o_crc_reg[28] ^ o_crc_reg[29] ^ d[0] ^ o_crc_reg[31] ^ d[2] ^ d[3] ^ o_crc_reg[25];
assign next_crc[28] = o_crc_reg[26] ^ d[5] ^ o_crc_reg[20] ^ o_crc_reg[29] ^ o_crc_reg[30] ^ d[1] ^ d[2];
assign next_crc[29] = d[4] ^ o_crc_reg[27] ^ o_crc_reg[21] ^ o_crc_reg[30] ^ d[0] ^ d[1] ^ o_crc_reg[31];
assign next_crc[30] = o_crc_reg[28] ^ d[0] ^ o_crc_reg[22] ^ o_crc_reg[31] ^ d[3];
assign next_crc[31] = o_crc_reg[29] ^ o_crc_reg[23] ^ d[2];
endmodule

