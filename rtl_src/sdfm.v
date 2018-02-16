/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: sdfm.v
 *
 *  @brief: sigma-delta filter module (top - module)
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 14.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module SDFM
(
  input  wire        EXTRSTn,   // external reset
  input  wire        EXTCLK,    // external clock
  input  wire [1:0]  DSDIN,     // direct stream data input
  input  wire [1:0]  SDCLK,     // sigma-delta clock synchronization
  input  wire        RD,        // reading data
  input  wire        WR,        // write data
  input  wire [15:0] ADDR,      // address bus
  inout  wire [31:0] DATA,      // input/output data bus
  output wire        IRQ        // interrupt request
);

  // general
  wire SYSRSTn;   // system reset
  wire SYSCLK;    // system clock
  
  // rcu
  wire rcu_rsten_reg; // system reset enable
  wire rcu_clken_reg; // system clock enable

  // icu
  wire [3:0]  icu_mod_regx;     // input mode
  wire [7:0]  icu_div_regx;     // ratio system clock dividing for mode 3
  wire [1:0]  icu_err_signal;   // signal detecter error clock input

  // data filters
  wire [15:0] dfilt_dec_regx;         // data filter decimation ratio (oversampling ratio)
  wire [1:0]  dfilt_en_regx;          // data filter enable
  wire [3:0]  dfilt_st_regx;          // data filter structure
  wire [9:0]  dfilt_sh_regx;          // value shift bits for data filter
  wire [63:0] dfilt_data_outx;        // filter data output
  wire [1:0]  dfilt_update_signalx;   // signal filter data update
  
  // comparators
  wire [15:0] comp_dec_regx;        // comparator data decimation ratio (oversampling ratio)
  wire [1:0]  comp_en_regx;         // comparator enable
  wire [1:0]  comp_signed_regx;     // signed data comparator enable
  wire [3:0]  comp_st_regx;         // comparator filter structure
  wire [63:0] comp_ltrd_regx;	      // comparator value low threshold
  wire [63:0] comp_htrd_regx;		    // comparator value high threshold
  wire [63:0] comp_data_outx;       // comparator data output
  wire [1:0]  comp_update_signalx;  // signal comparator data update
  wire [1:0]  comp_low_signalx;     // signal comparator data < low threshold
  wire [1:0]  comp_high_signalx;	  // signal comparator data >= high threshold

  // fifo
  wire [1:0]  fifo_en_regx;           // fifo enable
  wire [7:0]  fifo_level_regx;        // fifo interrupt level
  wire [1:0]  fifo_rd_signalx;        // signal read FDATA register
  wire [7:0]  fifo_statx;             // status fifo
  wire [1:0]  fifo_levelup_signalx;   // signal level up fifo status
  wire [1:0]  fifo_full_signalx;      // signal full fifo status

  
  // Reset and clock unit
  RCU rcu
  (
    .EXTRSTn(EXTRSTn),
    .EXTCLK (EXTCLK),
    .rsten  (rcu_rsten_reg),
    .clken  (rcu_clken_reg),
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK)
  );
  
  // Registers map
  REGMAP regmap
  (
    // general
    .EXTRSTn(EXTRSTn),
    .EXTCLK (EXTCLK),
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK),
    .WR     (WR),
    .RD     (RD),
    .ADDR   (ADDR),
    .DATA   (DATA),
    .IRQ    (IRQ),

    // rcu
    .rcu_rsten_reg(rcu_rsten_reg),
    .rcu_clken_reg(rcu_clken_reg),

    // input controls
    .icu_mod_regx   (icu_mod_regx),
    .icu_div_regx   (icu_div_regx),
    .icu_err_signalx(icu_err_signalx),

    // data filters
    .dfilt_dec_regx      (dfilt_dec_regx),
    .dfilt_en_regx       (dfilt_en_regx),
    .dfilt_st_regx       (dfilt_st_regx),
    .dfilt_sh_regx       (dfilt_sh_regx),
    .dfilt_data_outx     (dfilt_data_outx),
    .dfilt_update_signalx(dfilt_update_signalx),

    // comparators
    .comp_dec_regx      (comp_dec_regx),
    .comp_en_regx       (comp_en_regx),
	  .comp_signed_regx   (comp_signed_regx),
	  .comp_st_regx       (comp_st_regx),
	  .comp_ltrd_regx     (comp_ltrd_regx),
	  .comp_htrd_regx     (comp_htrd_regx),
	  .comp_data_outx     (comp_data_outx),
    .comp_update_signalx(comp_update_signalx),
	  .comp_low_signalx   (comp_low_signalx),
	  .comp_high_signalx  (comp_high_signalx),

    // fifo
    .fifo_en_regx        (fifo_en_regx),
    .fifo_level_regx     (fifo_level_regx),
    .fifo_rd_signalx     (fifo_rd_signalx),
    .fifo_statx          (fifo_statx),
    .fifo_levelup_signalx(fifo_levelup_signalx),
    .fifo_full_signalx   (fifo_full_signalx)
  );

  // Sigma-delta demodulator channels
  genvar i;
  generate
    begin : SD_CHANNELS
      for(i = 0; i < 2; i = i + 1)
        begin : SD_CHANNEL
          CHANNEL channel
          (
            // general
            .SYSRSTn(SYSRSTn),
            .SYSCLK (SYSCLK),
            .DSDIN  (DSDIN[i]),
            .SDCLK  (SDCLK[i]),

            // input control
            .icu_mod_reg   (icu_mod_regx  [1 + i * 2 : i * 2]),
            .icu_div_reg   (icu_div_regx  [3 + i * 4 : i * 4]),
            .icu_err_signal(icu_err_signal[i]),

            // data filter
            .dfilt_dec_reg      (dfilt_dec_regx      [7 + i * 8 : i * 8]),
            .dfilt_en_reg       (dfilt_en_regx       [i]),
            .dfilt_st_reg       (dfilt_st_regx       [1 + i * 2 : i * 2]),
            .dfilt_sh_reg       (dfilt_sh_regx       [4 + i * 5 : i * 5]),
            .dfilt_data_out     (dfilt_data_outx     [31 + 32 * i : 32 * i]),
            .dfilt_update_signal(dfilt_update_signalx[i]),

            // comparator
            .comp_dec_reg      (comp_dec_regx      [7 + i * 8 : i * 8]),
            .comp_en_reg       (comp_en_regx       [i]),
			      .comp_signed_reg   (comp_signed_regx   [i]),
			      .comp_st_reg       (comp_st_regx       [1 + i * 2 : i * 2]),
			      .comp_ltrd_reg     (comp_ltrd_regx     [31 + 32 * i : 32 * i]),
			      .comp_htrd_reg     (comp_htrd_regx     [31 + 32 * i : 32 * i]),
			      .comp_data_out     (comp_data_outx     [31 + 32 * i : 32 * i]),
            .comp_update_signal(comp_update_signalx[i]),
			      .comp_low_signal   (comp_low_signalx   [i]),
			      .comp_high_signal  (comp_high_signalx  [i]),

            // fifo
            .fifo_en_reg        (fifo_en_regx        [i]),
            .fifo_level_reg     (fifo_level_regx     [3 + 4 * i : 4 * i]),
            .fifo_rd_signal     (fifo_rd_signalx     [i]),
            .fifo_stat          (fifo_statx          [3 + 4 * i : 4 * i]),
            .fifo_levelup_signal(fifo_levelup_signalx[i]),
            .fifo_full_signal   (fifo_full_signalx   [i])
          );
        end
    end
  endgenerate
  
  

endmodule
