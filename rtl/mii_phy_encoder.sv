module mii_phy_encoder(

    input i_clk,
    input i_reset,

    input wire enet_tx_clk,
    output reg enet_tx_en,
    output reg enet_tx_er,
    output reg [3:0] enet_tx_data,

    input tx_en,
    input [7:0] tx_data,
    output reg tx_ready
);

    localparam MTU = 1518;
    localparam MIN_FRAME_SIZE = 60; // not including FCS

    reg [7:0] the_buffer[MTU];
    reg [11:0] buffer_len;
    reg [11:0] sender_idx;
    reg high_nibble;

    reg packet_can_send;        // i_clk -> enet_tx_clk
    reg packet_send_complete;   // enet_tx_clk -> i_clk

    reg [2:0] crc_wait;
    reg [3:0] crc_index;

    reg [7:0] main_state;
    reg [7:0] sender_state;

    localparam SM_RESET=0;
    localparam SM_BUFFERING=1;
    localparam SM_PAD=2;
    localparam SM_CRC_WAIT=3;
    localparam SM_CRC=4;

    localparam SS_RESET=0;
    localparam SS_RTS=1; // ready to send
    localparam SS_SENDING=2;

     wire [31:0] o_crc_reg;
    wire [7:0] o_crc;
    reg [7:0] d;
    reg i_calc;
    reg i_d_valid;

    wire [31:0] crc_reg = ~o_crc_reg;

    mii_net_crc32 crc(
        .i_clk,
        .i_reset,
        .o_crc_reg,
        .o_crc,
        .d(tx_data),
        .i_calc,
        .i_d_valid
    );

    assign packet_can_send = main_state == SM_RESET;
    assign tx_ready = !packet_can_send || packet_send_complete;

    assign i_calc = tx_en && (main_state == SM_RESET || main_state == SM_BUFFERING);
    assign i_d_valid = i_calc || main_state == SM_PAD || main_state == SM_CRC_WAIT || main_state == SM_CRC;

    always @(posedge i_clk) begin
        if (i_reset) begin
            main_state <= SM_RESET;
            buffer_len <= 0;
        end
        if (main_state == SM_RESET) begin

            if (tx_en && tx_ready) begin
                main_state <= SM_BUFFERING;
                the_buffer[0] <= tx_data;
                buffer_len <= 1;
            end

        end
        else if (main_state == SM_BUFFERING) begin
            if (tx_en) begin
                the_buffer[buffer_len] <= tx_data;
                buffer_len <= buffer_len + 1;
            end
            else begin

                if (buffer_len < MIN_FRAME_SIZE) begin
                    the_buffer[buffer_len] <= 0;
                    buffer_len <= buffer_len + 1;
                end

                // skip buffering state if our addition has single byte pad has
                // fulfilled the minimum frame size.
                main_state <= (buffer_len + 1 >= MIN_FRAME_SIZE) ? SM_CRC_WAIT : SM_PAD;
                crc_wait <= 1;
            end
        end
        else if (main_state == SM_PAD) begin

            the_buffer[buffer_len] <= 0;
            buffer_len <= buffer_len + 1;
            if (buffer_len + 1 == MIN_FRAME_SIZE) begin
                main_state <= SM_CRC_WAIT;
                crc_wait <= 1;
            end
        end
        else if (main_state == SM_CRC_WAIT) begin

            if (crc_wait - 1 == 0)
                main_state <= SM_CRC;

            crc_wait <= crc_wait - 1;
            crc_index <= 0;
        end
        else if (main_state == SM_CRC) begin

            the_buffer[buffer_len] <= o_crc;
            buffer_len <= buffer_len + 1;

            crc_index <= crc_index + 1;
            if (crc_index == 3)
                main_state <= SM_RESET;
        end
    end

    wire [7:0] current_byte = the_buffer[sender_idx];

    always @(posedge enet_tx_clk) begin
        if (i_reset) begin
            sender_state <= SS_RESET;
            packet_send_complete <= 1;
        end
        else if (sender_state == SS_RESET) begin
            if (!packet_can_send)
                sender_state <= SS_RTS;
        end
        else if (sender_state == SS_RTS) begin
            if (packet_can_send) begin
                sender_state <= SS_SENDING;
                sender_idx <= 0;
                high_nibble <= 0;
            end
        end
        else if (sender_state == SS_SENDING) begin
            enet_tx_en <= 1;

            if (high_nibble) begin
                enet_tx_data <= the_buffer[sender_idx][7:4];
                sender_idx <= sender_idx + 1;
                high_nibble <= 0;
                if (sender_idx + 1 == buffer_len) begin
                    sender_state <= SS_RESET;
                    enet_tx_en <= 0;
                end
            end
            else begin
                enet_tx_data <= the_buffer[sender_idx][3:0];
                high_nibble <= 1;
            end
        end
    end








endmodule : mii_phy_encoder