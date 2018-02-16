/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: channel.v
 *
 *  @brief: sigma-delta channel
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 14.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module CHANNEL
(
  // general
  input  wire        SYSRSTn,               // system reset
  input  wire        SYSCLK,                // system clock
  input  wire        DSDIN,                 // direct stream data input
  input  wire        SDCLK,                 // sigma-delta clock synchronization

  // input control
  input  wire [1:0]  icu_mod_reg,     // input mode
  input  wire [3:0]  icu_div_reg,     // ratio system clock dividing for mode 3
  output wire        icu_err_signal,  // signal detecter error clock input

  // data filter
  input  wire [7:0]  dfilt_dec_reg,         // data filter decimation ratio (oversampling ratio)
  input  wire        dfilt_en_reg,          // data filter enable
  input  wire [1:0]  dfilt_st_reg,          // data filter structure
  input  wire [4:0]  dfilt_sh_reg,          // value shift bits for data filter
  output wire [31:0] dfilt_data_out,        // filter data output
  output wire        dfilt_update_signal,   // signal filter data update
  
  // comparator
  input  wire [7:0]  comp_dec_reg,        // comparator data decimation ratio (oversampling ratio)
  input  wire        comp_en_reg,         // comparator enable
  input  wire        comp_signed_reg,     // signed data comparator enable
  input  wire [1:0]  comp_st_reg,         // comparator filter structure
  input  wire [31:0] comp_ltrd_reg,       // comparator value low threshold
  input  wire [31:0] comp_htrd_reg,	      // comparator value high threshold
  output wire [31:0] comp_data_out,       // comparator data output
  output wire        comp_update_signal,  // signal comparator data update
  output wire        comp_low_signal,		  // signal comparator data < low threshold
  output wire        comp_high_signal,	  // signal comparator data >= high threshold

  // fifo
  input  wire        fifo_en_reg,           // fifo enable
  input  wire [3:0]  fifo_level_reg,        // fifo interrupt level
  input  wire        fifo_rd_signal,        // signal read FDATA register
  output wire [3:0]  fifo_stat,             // status fifo
  output wire        fifo_levelup_signal,   // signal level up fifo status
  output wire        fifo_full_signal       // signal full fifo status
);

  wire sd_dsd_in;
  wire sd_clk_in;

  // input control unit
  ICU icu
  (
    .SYSRSTn   (SYSRSTn),
    .SYSCLK    (SYSCLK),
    .DSDIN     (DSDIN),
    .SDCLK     (SDCLK),
    .mod       (icu_mod_reg),
    .div       (icu_div_reg),
    .sd_dsd_in (sd_dsd_in),
    .sd_clk_in (sd_clk_in),
    .err_signal(icu_err_signal)
  );

  // filter data unit
  DFILT dfilt
  (
    .SYSRSTn            (SYSRSTn),
    .SYSCLK             (SYSCLK),
    .sd_dsd_in          (sd_dsd_in),
    .sd_clk_in          (sd_clk_in),
    .dfilt_dec_reg      (dfilt_dec_reg),
    .dfilt_en_reg       (dfilt_en_reg),
    .dfilt_st_reg       (dfilt_st_reg),
    .dfilt_sh_reg       (dfilt_sh_reg),
    .fifo_en_reg        (fifo_en_reg),
    .fifo_level_reg     (fifo_level_reg),
    .fifo_rd_signal     (fifo_rd_signal),
    .fifo_stat          (fifo_stat),
    .fifo_levelup_signal(fifo_levelup_signal),
    .fifo_full_signal   (fifo_full_signal),
    .dfilt_data_out     (dfilt_data_out),
    .dfilt_update_signal(dfilt_update_signal)
  );

  // comparator unit
  COMP comp
  (
    .SYSRSTn           (SYSRSTn),
    .SYSCLK            (SYSCLK),
    .sd_dsd_in         (sd_dsd_in),
    .sd_clk_in         (sd_clk_in),
    .comp_dec_reg      (comp_dec_reg),
    .comp_en_reg       (comp_en_reg),
	  .comp_signed_reg   (comp_signed_reg),
	  .comp_st_reg       (comp_st_reg),
	  .comp_ltrd_reg     (comp_ltrd_reg),
	  .comp_htrd_reg     (comp_htrd_reg),
    .comp_data_out     (comp_data_out),
    .comp_update_signal(comp_update_signal),
	  .comp_low_signal   (comp_low_signal),
	  .comp_high_signal  (comp_high_signal)
  );

endmodule
