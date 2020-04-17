module mii_net_top(
    input i_sys_clk,
    input i_nreset,
    input i_nsend,

    output reg mdc,
    inout wire mdio,


    output ledr0,

    input [17:0] i_switches,
    output [7:0] o_ledg,

    output wire enet_nreset_o,

    input wire enet_tx_clk,
    output reg enet_tx_en,
    output wire enet_tx_er,
    output reg [3:0] enet_tx_data,

    input enet_rx_clk,
    input enet_rx_dv,
    input wire [3:0] enet_rx_data,

    output wire [3:0] dbg_data,
    output wire dbg_valid,
    output wire dbg_clk,

    output wire [6:0] ssegs[8]

);

    assign enet_tx_er = 0;
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
    reg [31:0] buffer_len;
    reg last_rx_dv;

    wire [31:0] my_nibble = last_rx_dv ? nibble_count:0;
    
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
                buffer_len <= (my_nibble + 1) >> 1;
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


    reg tx_en;
    reg [7:0] tx_data;
    wire tx_ready;

    mii_phy_encoder enc(
        .i_clk(i_sys_clk),
        .i_reset(~i_nreset),
        .enet_tx_clk,
        .enet_tx_en,
        .enet_tx_data,

        .tx_en,
        .tx_data,
        .tx_ready
    );

    reg is_sending;
    reg [15:0] send_idx;

    always @(posedge i_sys_clk) begin
        if (~i_nreset) begin
            tx_en <= 0;
            tx_data <= 0;
            is_sending <= 0;
            send_idx <= 0;
        end
        else begin
            if (!is_sending && ~i_nsend && tx_ready) begin
                is_sending <= 1;
                send_idx <= 0;
            end
            if (is_sending) begin // next cycle

                if (send_idx == buffer_len) begin
                    is_sending <= 0;
                    tx_en <= 0;
                end
                else begin
                    tx_data <= frame_recv[send_idx[15:2]][3-send_idx[1:0]];
                    tx_en <= 1;

                    send_idx <= send_idx + 1;
                end
            end
        end
    end


//    always @(posedge tx_clk) begin
//        enet_tx_en <= (tx_index <= 143) && !i_nsend;
//        enet_tx_data <= tx_nibble;
//        if (i_nsend)
//            tx_index <= 0;
//        else begin
//            if (tx_index < 32'hFFFF_FFFF)
//                tx_index <= tx_index + 1;
//        end
//    end


// TX TEST
//    wire tx_clk;
//
//    reg [3:0] tx_nibble;
//    // assign seg_display = tx_index;
//    assign o_ledg[0] = enet_tx_en;
//    assign o_ledg[1] = i_nsend;
//
//    assign tx_clk = enet_tx_clk;
//
//    always @(posedge tx_clk) begin
//        enet_tx_en <= (tx_index <= 143) && !i_nsend;
//        enet_tx_data <= tx_nibble;
//        if (i_nsend)
//            tx_index <= 0;
//        else begin
//            if (tx_index < 32'hFFFF_FFFF)
//                tx_index <= tx_index + 1;
//        end
//    end
//
//    reg [31:0] tx_index;
//    always @(*) begin
//        case(tx_index)
//31'd0: tx_nibble=4'h5;
//31'd1: tx_nibble=4'h5;
//31'd2: tx_nibble=4'h5;
//31'd3: tx_nibble=4'h5;
//31'd4: tx_nibble=4'h5;
//31'd5: tx_nibble=4'h5;
//31'd6: tx_nibble=4'h5;
//31'd7: tx_nibble=4'h5;
//31'd8: tx_nibble=4'h5;
//31'd9: tx_nibble=4'h5;
//31'd10: tx_nibble=4'h5;
//31'd11: tx_nibble=4'h5;
//31'd12: tx_nibble=4'h5;
//31'd13: tx_nibble=4'h5;
//31'd14: tx_nibble=4'h5;
//31'd15: tx_nibble=4'hd;
//31'd16: tx_nibble=4'hf;
//31'd17: tx_nibble=4'hf;
//31'd18: tx_nibble=4'hf;
//31'd19: tx_nibble=4'hf;
//31'd20: tx_nibble=4'hf;
//31'd21: tx_nibble=4'hf;
//31'd22: tx_nibble=4'hf;
//31'd23: tx_nibble=4'hf;
//31'd24: tx_nibble=4'hf;
//31'd25: tx_nibble=4'hf;
//31'd26: tx_nibble=4'hf;
//31'd27: tx_nibble=4'hf;
//31'd28: tx_nibble=4'h0;
//31'd29: tx_nibble=4'h0;
//31'd30: tx_nibble=4'h0;
//31'd31: tx_nibble=4'he;
//31'd32: tx_nibble=4'hc;
//31'd33: tx_nibble=4'h4;
//31'd34: tx_nibble=4'hc;
//31'd35: tx_nibble=4'h6;
//31'd36: tx_nibble=4'h4;
//31'd37: tx_nibble=4'h2;
//31'd38: tx_nibble=4'hf;
//31'd39: tx_nibble=4'h2;
//31'd40: tx_nibble=4'h8;
//31'd41: tx_nibble=4'h0;
//31'd42: tx_nibble=4'h6;
//31'd43: tx_nibble=4'h0;
//31'd44: tx_nibble=4'h0;
//31'd45: tx_nibble=4'h0;
//31'd46: tx_nibble=4'h1;
//31'd47: tx_nibble=4'h0;
//31'd48: tx_nibble=4'h8;
//31'd49: tx_nibble=4'h0;
//31'd50: tx_nibble=4'h0;
//31'd51: tx_nibble=4'h0;
//31'd52: tx_nibble=4'h6;
//31'd53: tx_nibble=4'h0;
//31'd54: tx_nibble=4'h4;
//31'd55: tx_nibble=4'h0;
//31'd56: tx_nibble=4'h0;
//31'd57: tx_nibble=4'h0;
//31'd58: tx_nibble=4'h1;
//31'd59: tx_nibble=4'h0;
//31'd60: tx_nibble=4'h0;
//31'd61: tx_nibble=4'h0;
//31'd62: tx_nibble=4'h0;
//31'd63: tx_nibble=4'he;
//31'd64: tx_nibble=4'hc;
//31'd65: tx_nibble=4'h4;
//31'd66: tx_nibble=4'hc;
//31'd67: tx_nibble=4'h6;
//31'd68: tx_nibble=4'h4;
//31'd69: tx_nibble=4'h2;
//31'd70: tx_nibble=4'hf;
//31'd71: tx_nibble=4'h2;
//31'd72: tx_nibble=4'ha;
//31'd73: tx_nibble=4'h0;
//31'd74: tx_nibble=4'h5;
//31'd75: tx_nibble=4'h4;
//31'd76: tx_nibble=4'h5;
//31'd77: tx_nibble=4'h4;
//31'd78: tx_nibble=4'h1;
//31'd79: tx_nibble=4'h0;
//31'd80: tx_nibble=4'h0;
//31'd81: tx_nibble=4'h0;
//31'd82: tx_nibble=4'h0;
//31'd83: tx_nibble=4'h0;
//31'd84: tx_nibble=4'h0;
//31'd85: tx_nibble=4'h0;
//31'd86: tx_nibble=4'h0;
//31'd87: tx_nibble=4'h0;
//31'd88: tx_nibble=4'h0;
//31'd89: tx_nibble=4'h0;
//31'd90: tx_nibble=4'h0;
//31'd91: tx_nibble=4'h0;
//31'd92: tx_nibble=4'ha;
//31'd93: tx_nibble=4'h0;
//31'd94: tx_nibble=4'h5;
//31'd95: tx_nibble=4'h4;
//31'd96: tx_nibble=4'h5;
//31'd97: tx_nibble=4'h4;
//31'd98: tx_nibble=4'h2;
//31'd99: tx_nibble=4'h0;
//31'd100: tx_nibble=4'h0;
//31'd101: tx_nibble=4'h0;
//31'd102: tx_nibble=4'h0;
//31'd103: tx_nibble=4'h0;
//31'd104: tx_nibble=4'h0;
//31'd105: tx_nibble=4'h0;
//31'd106: tx_nibble=4'h0;
//31'd107: tx_nibble=4'h0;
//31'd108: tx_nibble=4'h0;
//31'd109: tx_nibble=4'h0;
//31'd110: tx_nibble=4'h0;
//31'd111: tx_nibble=4'h0;
//31'd112: tx_nibble=4'h0;
//31'd113: tx_nibble=4'h0;
//31'd114: tx_nibble=4'h0;
//31'd115: tx_nibble=4'h0;
//31'd116: tx_nibble=4'h0;
//31'd117: tx_nibble=4'h0;
//31'd118: tx_nibble=4'h0;
//31'd119: tx_nibble=4'h0;
//31'd120: tx_nibble=4'h0;
//31'd121: tx_nibble=4'h0;
//31'd122: tx_nibble=4'h0;
//31'd123: tx_nibble=4'h0;
//31'd124: tx_nibble=4'h0;
//31'd125: tx_nibble=4'h0;
//31'd126: tx_nibble=4'h0;
//31'd127: tx_nibble=4'h0;
//31'd128: tx_nibble=4'h0;
//31'd129: tx_nibble=4'h0;
//31'd130: tx_nibble=4'h0;
//31'd131: tx_nibble=4'h0;
//31'd132: tx_nibble=4'h0;
//31'd133: tx_nibble=4'h0;
//31'd134: tx_nibble=4'h0;
//31'd135: tx_nibble=4'h0;
//31'd136: tx_nibble=4'he;
//31'd137: tx_nibble=4'hf;
//31'd138: tx_nibble=4'hb;
//31'd139: tx_nibble=4'h8;
//31'd140: tx_nibble=4'h4;
//31'd141: tx_nibble=4'h0;
//31'd142: tx_nibble=4'h3;
//31'd143: tx_nibble=4'h1;
//
//
//
//            default: tx_nibble = 4'b0;
//        endcase
//    end


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

