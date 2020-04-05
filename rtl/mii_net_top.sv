module mii_net_top(
    input i_sys_clk,
    input i_nreset,

    output reg mdc,
    inout wire mdio,


    output ledr0,

    input [17:0] i_switches,
    output [7:0] o_ledg,

    output wire enet_nreset_o,

    input enet_rx_clk,
    input enet_rx_dv,
    input wire [3:0] enet_rx_data,

    output wire [3:0] dbg_data,
    output wire dbg_valid,
    output wire dbg_clk,

    output wire [6:0] ssegs[8]

);

    wire i_reset = ~i_nreset;
    assign enet_nreset_o = i_nreset;

    assign dbg_clk = enet_rx_clk;
    assign dbg_data = enet_rx_data;
    assign dbg_valid = enet_rx_dv;

    localparam msg_header={32'hffffffffff, 2'b01, 2'b01, 5'b10000, 5'd25, 2'b10};

    reg [63:0] my_msg;
    reg [7:0] msg_valid;

    assign ledr0 = i_reset || (^ i_switches);

    localparam clock_div_amt=50;
    reg [31:0] clock_div;

    reg [31:0] seg_display;
    sevenSegmentDisp d0(ssegs[0], seg_display[3:0]);
    sevenSegmentDisp d1(ssegs[1], seg_display[7:4]);
    sevenSegmentDisp d2(ssegs[2], seg_display[11:8]);
    sevenSegmentDisp d3(ssegs[3], seg_display[15:12]);
    sevenSegmentDisp d4(ssegs[4], seg_display[19:16]);
    sevenSegmentDisp d5(ssegs[5], seg_display[23:20]);
    sevenSegmentDisp d6(ssegs[6], seg_display[27:24]);
    sevenSegmentDisp d7(ssegs[7], seg_display[31:28]);

    reg [3:0] [7:0] frame_recv [256];

    reg [3:0] stored_nibble;
    reg [31:0] nibble_count;
    reg last_rx_dv;

    wire [31:0] my_nibble = last_rx_dv ? nibble_count:0;

    `define REV4(x) ({x[0],x[1],x[2],x[3]})
    // `define REV4(x) x

    always @(posedge enet_rx_clk) begin
        if (enet_rx_dv && i_switches[17]) begin
            begin
                if (my_nibble%2 == 0)
                    stored_nibble <= enet_rx_data; // {enet_rx_data, neg_nibble};
                else
                    if (my_nibble < 256*8) begin
                    if (my_nibble[2:1] == 0)
                        frame_recv[my_nibble[31:3]] [3] <= {enet_rx_data, stored_nibble};
                    if (my_nibble[2:1] == 1)
                        frame_recv[my_nibble[31:3]] [2] <= {enet_rx_data, stored_nibble};
                    if (my_nibble[2:1] == 2)
                        frame_recv[my_nibble[31:3]] [1] <= {enet_rx_data, stored_nibble};
                    if (my_nibble[2:1] == 3)
                        frame_recv[my_nibble[31:3]] [0] <= {enet_rx_data, stored_nibble};
                end
                nibble_count <= my_nibble+1;
            end
        end

        last_rx_dv <= enet_rx_dv;
    end

    always @(posedge i_sys_clk) begin
        seg_display <= frame_recv[i_switches[7:0]];
    end

    reg [20:0] current_md;
    reg [4:0] md_index;

    localparam md_count=4;
    always @(*) case (md_index)
        0: current_md = {5'd25, 16'b111111111111};

        1: current_md = { 5'd0, 16'b1010000100000000}; // force 100 full duplex mode
        2: current_md = { 5'd0, 16'b1010000100000000};
        // 2: current_md = { 5'd0, 16'b1000000000000000}; // PHY reset

        3: current_md = {5'd25, 16'b000000000000};
        default: current_md = 0;
    endcase

    reg md_write;
    reg [4:0] reg_addr;
    reg [15:0] w_data;
    reg stb;
    reg md_stall;

    reg mdio_en;
    reg mdio_o;
    assign mdio = mdio_en ? mdio_o:1'bz;

    mii_management mng(
        .i_clk(i_sys_clk),
        .i_reset,

        // Write/Read control interface
        .is_write(1),
        .phys_addr(5'b10000),
        .reg_addr(current_md[20:16]),
        .i_data(current_md[15:0]),
        .stb(md_index < md_count),

        // inputs TODO
        .stall(md_stall),

        // Management interface
        .enet_mdc(mdc),
        .enet_mdio_en(mdio_en),
        .enet_o_mdio(mdio_o),
        .enet_i_mdio(mdio)
    );

    always @(posedge i_sys_clk) begin
        if (i_reset) begin
            md_index <= 0;
        end
        else begin
            if (!md_stall && md_index < md_count)
                md_index <= md_index+1;
        end
    end

    // always @(posedge i_sys_clk) begin
    //     if (i_reset) begin
    //         clock_div <= clock_div_amt;
    //         my_msg <= {msg_header, i_switches[15:0]};
    //         msg_valid <= 65;
    //     end
    //     else if (clock_div != 0)
    //         clock_div <= clock_div - 1;
    //     else begin
    //         clock_div <= clock_div_amt;

    //         if (mdc == 0) begin
    //             mdc <= 1;
    //             mdio_o <= my_msg[63];
    //             my_msg <= my_msg << 1;
    //             if (msg_valid > 0)
    //                 msg_valid <= msg_valid - 1;
    //         end
    //         else 
    //             mdc <= 0;
    //     end
    // end


endmodule: mii_net_top

