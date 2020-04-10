module tb_net_crc32();

    reg i_sys_clk;
    initial i_sys_clk = 0;

    reg i_nreset;
    initial i_nreset = 1;

    initial
        begin
            $dumpfile("test.vcd");
            $dumpvars(0, tb_net_crc32);
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


    wire [31:0] o_crc_reg;
    wire [7:0] o_crc;
    reg [7:0] d;
    reg i_calc;
    reg i_d_valid;

    localparam full_packet_len = 60;
    reg [7:0] my_packet [full_packet_len];
    reg [7:0] packet_len = full_packet_len;
    reg [7:0] wait_len = 2;
    reg [7:0] checksum_len = 4;

    initial $readmemh("tb_net_crc32_packet.hex", my_packet);

    always @(posedge i_sys_clk) begin
        if (!i_nreset) begin
        end
        else if (packet_len > 0) begin
            $display("checksum: %h", o_crc_reg);
            d <= my_packet[full_packet_len - packet_len];

            packet_len <= packet_len - 1;

            i_calc <= 1;
            i_d_valid <= 1;
        end
        else if (wait_len > 0) begin
            wait_len <= wait_len - 1;
            i_calc <= 0;
            i_d_valid <= 1;
        end
        else if (checksum_len > 0) begin

            $display("checksum: %h", o_crc);
            i_calc <= 0;
            i_d_valid <= 1;
//
            checksum_len <= checksum_len - 1;
        end
        else begin

            $display("checksum: %h", ~o_crc_reg);
            $finish();

            // check checksum
        end
    end


    mii_net_crc32 ff(
        .i_clk(i_sys_clk),
        .i_reset(!i_nreset),
        .d(d),
        .i_d_valid,
        .i_calc,
        .i_init(1'b0),

        .o_crc_reg,
        .o_crc
    );

endmodule: tb_net_crc32

