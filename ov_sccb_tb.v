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
    reg [7:0] addr;
    reg [7:0] subaddr;
    reg [7:0] w_data;
    wire [7:0] r_data;
    reg tr_start;
    wire tr_end;

    // for counting the cycles
    reg [15:0] cycle;

    // module, parameters, instance, ports
    ov_sccb #() ov_sccb (.clk(clock),
                         .reset(reset),
                         .sio_d(sio_d),
                         .sio_c(sio_c),
                         .sccb_e(sccb_e),
                         .pwdn(pwdn),
                         .addr(addr),
                         .subaddr(subaddr),
                         .w_data(w_data),
                         .r_data(r_data),
                         .tr_start(tr_start),
                         .tr_end(tr_end));

    // Initial conditions; setup
    initial begin
        $timeformat(-9,1, "ns", 12);
        $monitor("%t, %b, CYCLE: %d", $realtime, clock, cycle);

		// Initial Conditions
		clock <= 0;
        cycle <= 0;
        reset <= 1'b0;

        tr_start <= 0;

        addr <= 8'h51;
        subaddr <= 8'h0A;

        w_data <= 8'b00110110;

        // Initialize clock
        #5
        clock <= 1'b0;
        tr_start <= 1'b1;

		// Deassert reset
        #100
        reset <= 1'b1;

        #400
        tr_start <= 1'b0;

        #100 $finish;
    end

    assign sio_d = ov_sccb.sio_oe ? 'bz : clock;

    always @ (posedge tr_end) begin
        if (tr_start && tr_end)
            $finish;
    end



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
