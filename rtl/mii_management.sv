module mii_management(
    input i_clk,
    input i_reset,

    input is_write,
    input [4:0] phys_addr,
    input [4:0] reg_addr,
    input [15:0] i_data,
    input stb,

    output reg stall,
    // o_data will hold the last value until a new stb is performed.
    // stall HIGH means data is not ready yet or write is in progress.
    output reg [15:0] o_data,


    output reg enet_mdc,
    output reg enet_mdio_en,
    output reg enet_o_mdio,
    input enet_i_mdio
);
    // divide clock to
    localparam clock_div_amt=50;
    reg [31:0] clock_div;

    reg [63:0] staged_data;
    reg [6:0] bits_to_send;
    reg [6:0] bits_to_read;
    reg is_read;

    reg [15:0] read_value;

    always @(posedge i_clk) begin
        if (i_reset) begin
            stall <= 0;
            o_data <= 0;
            enet_mdc <= 0;
            enet_mdio_en <= 0;
            enet_o_mdio <= 0;
            bits_to_read <= 0;
        end
        else begin
            if (!stall && stb) begin
                if (is_write) begin
                    staged_data <= {32'hffffffffff, 2'b01, 2'b01, phys_addr, reg_addr, 2'b10, i_data};
                    bits_to_send <= 64;
                    bits_to_read <= 0;
                    is_read <= 0;
                end
                else begin
                    staged_data <= {32'hffffffffff, 2'b01, 2'b10, phys_addr, reg_addr, 18'd0};
                    bits_to_send <= 46;
                    bits_to_read <= 18;
                    is_read <= 1;
                end
                stall <= 1;
            end

            if (clock_div != 0)
                clock_div <= clock_div - 1;
            else begin
                clock_div <= clock_div_amt;

                if (enet_mdc)
                    enet_mdc <= 0;
                else begin
                    enet_mdc <= 1;

                    // handle write
                    enet_mdio_en <= bits_to_send != 0;
                    enet_o_mdio <= staged_data[63];
                    staged_data <= staged_data << 1;

                    // handle read
                    if (is_read && bits_to_read > 1 && bits_to_read <= 17) begin
                        read_value[bits_to_read-1] <= enet_i_mdio;
                    end

                    if (bits_to_send != 0)
                        bits_to_send <= bits_to_send - 1;
                    else if (bits_to_read != 0)
                        bits_to_read <= bits_to_read - 1;

                    if (bits_to_send == 0 && bits_to_read == 0) begin
                        stall <= 0;
                        if (is_read)
                            o_data <= read_value;
                    end
                end
            end
        end
    end

endmodule: mii_management