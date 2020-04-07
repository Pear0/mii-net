module mii_phy_decoder(
    input i_clk,
    input i_reset,

    input enet_rx_clk,
    input enet_rx_dv,
    input [3:0] enet_rx_data,

    itf_frame_stream stream
);

    // FIFO

    /*
     * FIFO data contains 2 flags and a single byte.
     * data[9:8] - status enum
     * data[7:0] - data byte
     */

    localparam ST_IDLE = 2'b00;
    localparam ST_FRAME_START = 2'b01;
    localparam ST_FRAME_CONT = 2'b10;
    localparam ST_ERROR = 2'b11;

    reg wrreq;
    wire wrfull;
    reg [9:0] wrdata;

    reg rdreq;
    wire rdempty;
    wire [9:0] rddata;

    dcfifo #(
        .lpm_width(2+8),
        .lpm_numwords(16),
        .lpm_showahead("OFF")
    ) fifo(
        .aclr(i_reset),

        .wrclk(enet_rx_clk),
        .wrreq(wrreq),
        .wrfull(wrfull),
        .data(wrdata),

        .rdclk(i_clk),
        .rdreq(rdreq),
        .rdempty(rdempty),
        .q(rddata)
    );

    // Eth rx clk

    reg e_curr_frame_invalid;
    reg has_stored_nibble;
    reg [3:0] stored_nibble;

    always @(posedge enet_rx_clk) begin
        if (i_reset) begin
           e_curr_frame_invalid <= 0;
        end
        else if (!enet_rx_dv) begin
            has_stored_nibble <= 0;

        end
        else if (!has_stored_nibble) begin
            has_stored_nibble <= 1;
            stored_nibble <= enet_rx_data;
        end
        else begin
            if ()


        end
    end




    // System Clock




endmodule : mii_phy_decoder