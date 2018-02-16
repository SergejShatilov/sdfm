/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: comp.v
 *
 *  @brief: comparator unit
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 14.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module COMP
(
  input  wire        SYSRSTn,             // system reset
  input  wire        SYSCLK,              // system clock
  input  wire        sd_dsd_in,           // new direct stream data input
  input  wire        sd_clk_in,           // new sigma-delta clock synchronization

  input  wire [7:0]  comp_dec_reg,        // comparator data decimation ratio (oversampling ratio)
  input  wire        comp_en_reg,         // comparator enable
  input  wire        comp_signed_reg,     // signed data comparator enable
  input  wire [1:0]  comp_st_reg,         // comparator filter structure
  
  input  wire [31:0] comp_ltrd_reg,       // comparator value low threshold
  input  wire [31:0] comp_htrd_reg,	      // comparator value high threshold
  
  output wire [31:0] comp_data_out,       // comparator data output
  output wire        comp_update_signal,  // signal comparator data update
  
  output wire        comp_low_signal, 		// signal comparator data < low threshold
  output wire        comp_high_signal	  	// signal comparator data >= high threshold
);

  wire        osr_signal;
  reg  [2:0]  osr_reg;
  wire [31:0] comp_data;


  // generation signal data update
  assign comp_update_signal = (osr_reg[1:0] == 2'b10) && comp_en_reg; //FIXME: optimization
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      osr_reg <= 3'b000;
    else
      osr_reg <= {osr_signal, osr_reg[2:1]};
    



 // decimation control unit
  DCU dcu
  (
    .SYSRSTn   (SYSRSTn),
    .value_dec (comp_dec_reg),
    .clk_in    (sd_clk_in),
    .osr_signal(osr_signal)
  );
  
  // abstact filter unit (select mode signed - enable)
  FILT #(1) filt
  (
    .SYSRSTn  (SYSRSTn),
    .SYSCLK   (SYSCLK),
    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in),
    .osr      (osr_signal),
    .signed_en(comp_signed_reg),
    .structure(comp_st_reg),
    .data_out (comp_data)
  );

	  
  //===========================================================================================
  //=                              CLU (Comparator low unit)                                  =
  //===========================================================================================
  assign comp_low_signal = (comp_data < comp_ltrd_reg) && osr_signal;

  
  
  //===========================================================================================
  //=                              CHU (Comparator high unit)                                 =
  //===========================================================================================
  assign comp_high_signal = (comp_data >= comp_htrd_reg) && osr_signal;
  
  
      
endmodule
