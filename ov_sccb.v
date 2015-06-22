/*
----------------------------------------
Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------

Omnivision SCCB Protocol Implementation

Authors:  Greg M. Crist, Jr. (gmcrist@gmail.com)

Description:
  Implements the Omnivision SCCB protocol for use with Omnivision CMOS cameras

  Developed according to:
    Omnivision Serial Camera Control Bus (SCCB) Functional Specification
    Document Version 2.2
    Modified 25 June 2007

  Obtained From:
    URL:  http://www.ovt.com/download_document.php?type=document&DID=63
    Date: 02/19/2015


  Transmission Phases:
    Each phase consists of 9-bits
      * 8-bit sequential data
      * 1-bit Don't Care or NA, depending on whether the transmission is a write or read

    * 3-Phase write transmission cycle

    * 2-Phase write transmission cycle

    * 2-Phase read transmission cycle

*/
module ov_sccb(clk, reset, sio_d, sio_c, sccb_e, pwdn, addr, subaddr, w_data, r_data, tr_start, tr_end);
    input clk;           // Clock signal
    input reset;         // Reset signal (active-low)

    inout  sio_d;        // SCCB data (tri-state)
    output sio_c;        // SCCB clock
    output reg sccb_e;   // SCCB transmission enable
    output reg pwdn;     // Power-down

    input [7:0] addr;    // Address of device
    input [7:0] subaddr; // Sub-Address (Register) to write to
    input [7:0] w_data;  // Data to write to device
    output reg [7:0] r_data; // Data read from device

    input tr_start;      // Transmission start
    output tr_end;       // Transmission end

    reg cycle;
    wire write;
    wire read;

    reg sio_oe;
    reg sio_d_reg;

    // Bit counter
    reg [3:0] bit_cnt;  // bit counter

    // State variables
    reg [2:0] state,
         next_state;

    parameter s_idle    = 0,
              s_addr    = 1,
              s_subaddr = 2,
              s_read    = 3,
              s_write   = 4;

    assign write = addr[0] == 1'b0 ? 1'b1 : 1'b0;
    assign read = ~write;

    assign sio_d = sio_oe == 1'b1 ? sio_d_reg : 'bz;
    assign sio_c = sccb_e == 1'b1 ? 1'b1 : clk;

    assign tr_end = state == s_idle ? 1'b1 : 1'b0;

    always @ (posedge clk or negedge reset) begin
        if (~reset) begin
            cycle     <= 1'b0;
            sio_oe <= 1'b1;

            pwdn      <= 1'b0;
            sccb_e    <= 1'b1;
            sio_d_reg <= 1'bz;

            bit_cnt   <= 4'd0;

            state <= s_idle;

            r_data <= 8'bz;
        end
        else begin
            case (state)
                s_idle: begin
                    pwdn      <= 1'b1;
                    sccb_e    <= 1'b1;
                    sio_d_reg <= 1'b1;
                    sio_oe    <= 1'b1;

                    bit_cnt   <= 4'd0;
                    cycle     <= 1'b0;

                    state     <= tr_start ? s_addr : s_idle;
                end

                // Phase 1: Address
                s_addr: begin
                    sccb_e <= 1'b0;

                    if (bit_cnt < 4'd8) begin
                        sio_oe <= 1'b0;
                        sio_d_reg <= addr[7 - bit_cnt];
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                    else begin
                        sio_oe <= 1'b1;
                        sio_d_reg <= 1'b0;
                        bit_cnt <= 4'd0;

                        // Go to the read state if we are doing a two-step
                        state <= (read && cycle) ? s_read : s_subaddr;
                    end
                end

                // Phase 2: Sub-Address
                s_subaddr: begin
                    if (bit_cnt < 4'd8) begin
                        sio_oe <= 1'b0;
                        sio_d_reg <= w_data[7 - bit_cnt];
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                    else begin
                        sio_oe <= 1'b1;
                        sio_d_reg <= 1'b0;
                        bit_cnt <= 4'd0;

                        cycle <= read ? 1'b1 : 1'b0;
                        state <= read ? s_addr : s_write;
                    end
                end

                // Phase 2: Read data
                s_read: begin
                    if (bit_cnt < 4'd8) begin
                        sio_oe <= 1'b0;

                        r_data[7 - bit_cnt] <= sio_d;
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                    else begin
                        sio_oe <= 1'b1;
                        sio_d_reg <= 1'b1;
                        bit_cnt <= 4'd0;
                        state <= s_idle;
                    end
                end

                // Phase 3: Write data
                s_write: begin
                    if (bit_cnt < 4'd8) begin
                        sio_oe <= 1'b0;
                        sio_d_reg <= w_data[7 - bit_cnt];

                        bit_cnt <= bit_cnt + 1'b1;
                    end
                    else begin
                        bit_cnt <= 4'd0;
                        state <= s_idle;
                    end
                end
            endcase
        end
    end
endmodule
