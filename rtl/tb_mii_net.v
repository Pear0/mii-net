
module tb_mii_net();

    reg i_sys_clk;
    initial i_sys_clk = 0;

    reg i_nreset;
    initial i_nreset = 1;

    initial
 begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb_mii_net);
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


    mii_net_top ff(.i_sys_clk, .i_nreset, .i_switches(17'haaaaaa));

endmodule

