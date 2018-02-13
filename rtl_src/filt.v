/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: filt.v
 *
 *  @brief: filter abstract unit
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 13.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module FILT #(parameter signed_enable_sel = 0)
(
  input  wire        SYSRSTn,       // system reset
  input  wire        SYSCLK,        // system clock
  input  wire        sd_dsd_in,     // new direct stream data input
  input  wire        sd_clk_in,     // new sigma-delta clock synchronization
  input  wire        osr,           // oversampling ratio
  input  wire        signed_en,     // signed data comparator enable
  input  wire [1:0]  structure,     // data filter structure
  output wire [31:0] filt_data_out  // filter data output
);


  //-----------------------------------------------------------------------
  // filter with infinite impulse response (IIR)
  reg [31:0] CN1;
  reg [31:0] CN2;
  reg [31:0] CN3;

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      CN1 <= 32'h0000_0000;
    else if(signed_enable_sel)
      CN1 <= sd_dsd_in ? (CN1 + 32'h0000_0001) : signed_en ? (CN1 + 32'hFFFF_FFFF) : (CN1 + 32'h0000_0000);
    else
      CN1 <= sd_dsd_in ? (CN1 + 32'h0000_0001) : (CN1 + 32'hFFFF_FFFF);
      

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      CN2 <= 32'h0000_0000;
    else
      CN2 <= CN2 + CN1;

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      CN3 <= 32'h0000_0000;
    else
      CN3 <= CN3 + CN2;

  wire [31:0] iir_mux;
  assign iir_mux = ((structure == 2'b00) || (structure == 2'b10)) ? CN2 : //FIXME: optimization
                    (structure == 2'b01) ? CN1 : CN3;

                    
                    
  //-----------------------------------------------------------------------
  // filter with finite impulse response (FIR)
  reg  [31:0] DN0;
  reg  [31:0] DN1;
  reg  [31:0] DN2;
  reg  [31:0] DN3;
  reg  [31:0] DN4;
  reg  [31:0] DN5;
  wire [31:0] QN1;
  wire [31:0] QN2;
  wire [31:0] QN3;
  wire [31:0] QN4;

  assign QN1 = DN0 - DN1;   //FIXME: optimization
  assign QN2 = QN1 - DN2;
  assign QN3 = QN2 - DN3;
  assign QN4 = DN5 + QN2;

  always @ (negedge SYSRSTn or posedge osr)
    if(!SYSRSTn)
      DN0 <= 32'h0000_0000;
    else
      DN0 <= iir_mux;

  always @ (negedge SYSRSTn or posedge osr)
    if(!SYSRSTn)
      DN1 <= 32'h0000_0000;
    else
      DN1 <= DN0;

  always @ (negedge SYSRSTn or posedge osr)
    if(!SYSRSTn)
      DN2 <= 32'h0000_0000;
    else
      DN2 <= QN1;

  always @ (negedge SYSRSTn or posedge osr)
    if(!SYSRSTn)
      DN3 <= 32'h0000_0000;
    else
      DN3 <= QN2;

  always @ (negedge SYSRSTn or posedge osr)
    if(!SYSRSTn)
      DN4 <= 32'h0000_0000;
    else
      DN4 <= QN2;

  always @ (negedge SYSRSTn or posedge osr)
    if(!SYSRSTn)
      DN5 <= 32'h0000_0000;
    else
      DN5 <= DN4;

  wire [31:0] fir_out;
  assign fir_out = (structure == 2'b00) ? QN4 :
                   (structure == 2'b01) ? QN1 :
                   (structure == 2'b10) ? QN2 : QN3;

  assign filt_data_out = fir_out;
      
endmodule
