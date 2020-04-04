

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

    output wire [6:0] ssegs [8]

);

    wire i_reset = ~i_nreset;
	 assign enet_nreset_o = i_nreset;

	 assign dbg_clk = enet_rx_clk;
	 assign dbg_data = enet_rx_data;
	 assign dbg_valid = enet_rx_dv;
	
    localparam msg_header = {32'hffffffffff, 2'b01, 2'b01, 5'b10000, 5'd25, 2'b10};

    reg mdio_o;

    assign mdio = (msg_valid != 0) ? mdio_o : 1'bz;
    
    reg [63:0] my_msg;
    reg [7:0] msg_valid;

    assign ledr0 = i_reset || (^i_switches);

    localparam clock_div_amt = 50;
    reg [31:0] clock_div;

    sevenSegmentDisp d0(ssegs[0], rcv_count[3:0]);
    sevenSegmentDisp d1(ssegs[1], rcv_count[7:4]);
    sevenSegmentDisp d2(ssegs[2], rcv_count[11:8]);
    sevenSegmentDisp d3(ssegs[3], rcv_count[15:12]);
    sevenSegmentDisp d4(ssegs[4], rcv_count[19:16]);
    sevenSegmentDisp d5(ssegs[5], rcv_count[23:20]);
    sevenSegmentDisp d6(ssegs[6], rcv_count[27:24]);
    sevenSegmentDisp d7(ssegs[7], rcv_count[31:28]);

    reg [31:0] rcv_count;
    // assign o_ledg = rcv_count;

    reg last_rx_dv;
    always @(posedge enet_rx_clk) begin
        if (enet_rx_dv) begin
            rcv_count <= {rcv_count[27:0], enet_rx_data};
        end
        last_rx_dv <= enet_rx_dv;
    end


    always @(posedge i_sys_clk) begin
        if (i_reset) begin
            clock_div <= clock_div_amt;
            my_msg <= {msg_header, i_switches[15:0]};
            msg_valid <= 65;
        end
        else if (clock_div != 0)
            clock_div <= clock_div - 1;
        else begin
            clock_div <= clock_div_amt;

            if (mdc == 0) begin
                mdc <= 1;
                mdio_o <= my_msg[63];
                my_msg <= my_msg << 1;
                if (msg_valid > 0)
                    msg_valid <= msg_valid - 1;
            end
            else 
                mdc <= 0;
        end
    end


endmodule : mii_net_top

