`timescale 1ns / 1ps
`include "ov_sccb.v"
/*
----------------------------------------
Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------

Testbench for Omnivision SCCB Protocol Implementation

Authors:  Greg M. Crist, Jr. (gmcrist@gmail.com)

Description:
  Testbench for the ov_sccb module
*/
module ov_sccb_tb ();
    parameter CLOCKPERIOD = 10;

    reg reset;
    reg clock;

    wire sio_d;
    wire sio_c;
    wire sccb_e;
    wire pwdn;
    reg [7:0] chip_addr;
    reg [7:0] sub_addr;
    reg [7:0] w_data;
    wire [7:0] r_data;

    reg tr_start;

    wire done;
    wire busy;

    // for counting the cycles
    reg [15:0] cycle;

    // module, parameters, instance, ports
    ov_sccb #() ov_sccb (
        .clk(clock),
        .reset(reset),
        .sio_d(sio_d),
        .sio_c(sio_c),
        .sccb_e(sccb_e),
        .pwdn(pwdn),
        .addr(chip_addr),
        .subaddr(sub_addr),
        .w_data(w_data),
        .r_data(r_data),
        .tr_start(tr_start),
        .tr_end(tr_end),
        .busy(busy)
    );

    localparam CHIP_ADDR = 8'h42;

    // Initial conditions; setup
    initial begin
        $timeformat(-9,1, "ns", 12);
        $monitor("%t, %b, CYCLE: %d,     SIO_C: %b    SIO_D: %b", $realtime, clock, cycle, sio_c, sio_d);

        $timeformat(-9,1, "ns", 12);

        // Initial Conditions
        cycle <= 0;
        reset <= 1'b0;
        tr_start <= 1'b0;


        // Initialize clock
        #2
        clock <= 1'b0;

        // Deassert reset
        #5
        reset <= 1'b1;

        $display("Beginning write transactions");

        #100 write_sccb(CHIP_ADDR, 8'h00, 8'hCA);
        #100 write_sccb(CHIP_ADDR, 8'h0A, 8'hFE);
        #100 write_sccb(CHIP_ADDR, 8'h10, 8'hD0);
        #100 write_sccb(CHIP_ADDR, 8'h1A, 8'hBA);

        #200 $finish;
    end

//    assign sio_d = ov_sccb.sio_oe ? 'bz;

    task write_sccb;
        input [7:0] t_chip_addr;
        input [7:0] t_sub_addr;
        input [7:0] t_data;

        begin
            $display("Writing 0x%0x to register 0x%0x on chip 0x%0x", t_data, t_sub_addr, t_chip_addr);

            @ (posedge clock) begin
                chip_addr <= t_chip_addr;
                sub_addr  <= t_sub_addr;
                w_data    <= t_data;
                tr_start  <= 1'b1;
            end

            @ (posedge clock)
                tr_start  <= 1'b0;

            @ (posedge clock);
            @ (posedge clock);
            @ (posedge clock);

            while (busy && ~tr_end) begin
                @ (posedge clock);
            end
        end
    endtask


/**************************************************************/
/* The following can be left as-is unless necessary to change */
/**************************************************************/

    // Cycle Counter
    always @ (posedge clock)
        cycle <= cycle + 1;

    // Clock generation
    always #(CLOCKPERIOD / 2) clock <= ~clock;

/*
  Conditional Environment Settings for the following:
    - Icarus Verilog
    - VCS
    - Altera Modelsim
    - Xilinx ISIM
*/
// Icarus Verilog
`ifdef IVERILOG
    initial $dumpfile("vcdbasic.vcd");
    initial $dumpvars();
`endif

// VCS
`ifdef VCS
    initial $vcdpluson;
`endif

// Altera Modelsim
`ifdef MODEL_TECH
`endif

// Xilinx ISIM
`ifdef XILINX_ISIM
`endif
endmodule
