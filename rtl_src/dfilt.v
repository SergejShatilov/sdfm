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
  input  wire        SYSRSTn,             // system reset
  input  wire        SYSCLK,              // system clock

  input  wire        sd_dsd_in,           // new direct stream data input
  input  wire        sd_clk_in,           // new sigma-delta clock synchronization
  
  input  wire [7:0]  dfilt_dec_reg,       // filter decimation ratio (oversampling ratio)
  input  wire        dfilt_en_reg,        // data filter enable
  input  wire [1:0]  dfilt_st_reg,        // data filter structure
  input  wire [4:0]  dfilt_sh_reg,        // value shift bits for data filter

  input  wire        fifo_en_reg,         // fifo enable
  input  wire [3:0]  fifo_level_reg,      // fifo interrupt level
  input  wire        fifo_rd_signal,      // signal read FDATA register

  output wire [3:0]  fifo_stat,           // status fifo
  output wire        fifo_levelup_signal, // signal level up fifo status
  output wire        fifo_full_signal,    // signal full fifo status

  output wire [31:0] dfilt_data_out,      // filter data output
  output wire        dfilt_update_signal  // signal filter data update
);

  wire [31:0] filt_data;
  wire [31:0] shift_data;
  wire [31:0] fifo_data;

  wire        osr_signal;
  reg  [2:0]  osr_reg;


  // generation signal data update

  assign dfilt_update_signal = (osr_reg[1:0] == 2'b10) && dfilt_en_reg; //FIXME: optimization
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      osr_reg <= 3'b000;
    else
      osr_reg <= {osr_signal, osr_reg[2:1]};


  // decimation control unit
  DCU dcu
  (
    .SYSRSTn   (SYSRSTn),
    .value_dec (dfilt_dec_reg),
    .clk_in    (sd_clk_in),
    .osr_signal(osr_signal)
  );
  
  // abstact filter unit (select mode signed - disable)
  FILT #(0) filt
  (
    .SYSRSTn  (SYSRSTn),
    .SYSCLK   (SYSCLK),
    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in),
    .osr      (osr_signal),
    .signed_en(1'b0),
    .structure(dfilt_st_reg),
    .data_out (filt_data)
  );
  
  // shift register data unit
  SHIFT shift
  (
    .bits    (dfilt_sh_reg),
    .data_in (filt_data),
    .data_out(shift_data)
  );

  // "first in, first out" buffer unit
  FIFO fifo
  (
    .SYSRSTn    (SYSRSTn),
    .SYSCLK     (SYSCLK),
    .enable     (fifo_en_reg),
    .level      (fifo_level_reg),
    .rd         (fifo_rd_signal),
    .data_in    (shift_data),
    .data_update(dfilt_update_signal),
    .stat       (fifo_stat),
    .levelup    (fifo_levelup_signal),
    .full       (fifo_full_signal),
    .data_out   (fifo_data)
  );

  assign dfilt_data_out = dfilt_en_reg ? fifo_data : 32'h0000_0000;
      
endmodule
 