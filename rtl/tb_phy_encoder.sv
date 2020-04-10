module tb_phy_encoder();

    reg i_sys_clk;
    initial i_sys_clk = 0;

    reg i_nreset;
    initial i_nreset = 1;

    initial
        begin
            $dumpfile("test.vcd");
            $dumpvars(0, tb_phy_encoder);
        end


    initial begin
        i_sys_clk = 1;
        #1;
        i_sys_clk = 0;
        #1;

        i_nreset = 0;

        i_sys_clk = 1;
        #1;
        i_sys_clk = 0;
        #1;

        i_nreset = 1;

        i_sys_clk = 1;
        #1;
        i_sys_clk = 0;
        #1;
    end

      always
        begin
            i_sys_clk = 1'b1;
            #1;

            i_sys_clk = 1'b0;
            #1;
        end


    wire tx_clk = !i_sys_clk;

    reg tx_en;
    reg [7:0] tx_data;
    wire tx_ready;

    localparam full_packet_len = 60;
    reg [7:0] my_packet [full_packet_len];
    reg [7:0] packet_len = full_packet_len;
    reg [7:0] wait_len = 200;


    initial $readmemh("tb_net_crc32_packet.hex", my_packet);

    always @(posedge i_sys_clk) begin
        if (!i_nreset) begin
        end
        else if (packet_len > 0) begin
            tx_en <= 1;
            tx_data <= my_packet[full_packet_len - packet_len];

            packet_len <= packet_len - 1;

        end
        else if (wait_len > 0) begin
            tx_en <= 0;
            wait_len <= wait_len - 1;
        end
        else begin

            $display("Done");
            $finish();

            // check checksum
        end
    end



    mii_phy_encoder ff(
        .i_clk(i_sys_clk),
        .i_reset(!i_nreset),
        .tx_en,
        .tx_data,
        .tx_ready,
        .enet_tx_clk(tx_clk)
    );


endmodule: tb_phy_encoder

