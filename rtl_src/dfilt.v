/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: dfilt.v
 *
 *  @brief: data filter unit
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 13.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module DFILT
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock

  input  wire        sd_dsd_in,         // new direct stream data input
  input  wire        sd_clk_in,         // new sigma-delta clock synchronization
  
  input  wire [7:0]  reg_filtdec,       // filter decimation ratio (oversampling ratio)
  input  wire        reg_filten,        // data filter enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  input  wire [4:0]  reg_filtsh,        // value shift bits for data filter

  // fifo
  input  wire        reg_fifoen,        // fifo enable
  input  wire [3:0]  reg_fifoilvl,      // fifo interrupt level
  input  wire        fifo_rd,           // signal read FDATA register

  output wire [3:0]  fifo_stat,         // status fifo
  output wire        fifo_lvlup,        // signal level up fifo status
  output wire        fifo_full,         // signal full fifo status

  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update   // signal filter data update
);

  wire        osr;
  wire [31:0] filt_data;
  wire [31:0] shift_data;

  
  DCU dcu
  (
    .SYSRSTn(SYSRSTn),
    .value_dec(reg_filtdec),
    .clk_in(sd_clk_in),
    .osr(osr)
  );
  
  
  FILT #(0) filt
  (
    .SYSRSTn(SYSRSTn),
    .SYSCLK(SYSCLK),
    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in),
    .osr(osr),
    .structure(reg_filtst),
    .filt_data_out(filt_data)  
  );
  
  
  SHIFT shift
  (
    .bits(reg_filtsh),
    .data_in(filt_data),
    .data_out(shift_data)
  );
  
  
  
  //-----------------------------------------------------------------------
  // generation signal data update
  
  reg [2:0] reg_osr;
  
  assign filt_data_update = (reg_osr[1:0] == 2'b10) && reg_filten; //FIXME: optimization
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_osr <= 3'b000;
    else
      reg_osr <= {osr, reg_osr[2:1]};
      


  wire [31:0] data_fifo;

  FIFO fifo
  (
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK),

    .reg_fifoen  (reg_fifoen),
    .reg_fifoilvl(reg_fifoilvl),
    .fifo_rd     (fifo_rd),

    .fifo_data_in    (shift_data),
    .fifo_data_update(filt_data_update),

    .fifo_stat (fifo_stat),
    .fifo_lvlup(fifo_lvlup),
    .fifo_full (fifo_full),

    .fifo_data_out(data_fifo)
  );



  assign filt_data_out = reg_filten ? data_fifo : 32'h0000_0000;
  

      
endmodule
 
