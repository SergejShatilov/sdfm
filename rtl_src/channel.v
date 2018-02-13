//===============================================
// Channel sigma-delta
//=============================================== 

module CHANNEL
(
  // general
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        DSDIN,             // direct stream data input
  input  wire        SDCLK,             // sigma-delta clock synchronization

  // input control
  input  wire [1:0]  reg_inmod,         // input mode
  input  wire [3:0]  reg_indiv,         // ratio system clock dividing for mode 3

  output wire        detect_err,        // signal detecter error clock input

  // data filter
  input  wire [7:0]  reg_filtdec,       // data filter decimation ratio (oversampling ratio)
  input  wire        reg_filten,        // data filter enable
  input  wire        reg_filtask,       // data filter asknewledge enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  input  wire [4:0]  reg_filtsh,        // value shift bits for data filter
  
  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update,  // signal filter data update
  
  // comparator
  input  wire [7:0]  reg_compdec,       // comparator data decimation ratio (oversampling ratio)
  input  wire        reg_compen,        // comparator enable
  input  wire        reg_compsen,       // signed data comparator enable
  input  wire [1:0]  reg_compst,        // comparator filter structure
  input  wire        reg_compilen,      // enable interrupt comparator for mode low threshold
  input  wire        reg_compihen,      // enable interrupt comparator for mode high threshold
  input  wire        reg_complclrflg,   // hardware clear flags comparators for mode low threshold
  input  wire        reg_comphclrflg,   // hardware clear flags comparators for mode high threshold
  
  input  wire [31:0] reg_compltrd,      // comparator value low threshold
  input  wire [31:0] reg_comphtrd,	    // comparator value high threshold
  
  output wire [31:0] comp_data_out,     // comparator data output
  output wire        comp_data_update,  // signal comparator data update
  
  output wire        comp_data_low,		  // signal comparator data < low threshold
  output wire        comp_data_high,	  // signal comparator data >= high threshold

  // fifo
  input  wire        reg_fifoen,        // fifo enable
  input  wire [3:0]  reg_fifoilvl,      // fifo interrupt level
  input  wire        fifo_rd,           // signal read FDATA register

  output wire [3:0]  fifo_stat,         // status fifo
  output wire        fifo_lvlup,        // signal level up fifo status
  output wire        fifo_full          // signal full fifo status
);

  //-----------------------------------------------------------
  // Input control unit
  ICU icu
  (
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK),
    .DSDIN(DSDIN),
    .SDCLK(SDCLK),

    .reg_inmod(reg_inmod),
    .reg_indiv(reg_indiv),

    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in),

    .detect_err(detect_err)
  );



  //-----------------------------------------------------------
  // Filter data unit
  DFILT dfilt
  (
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK),

    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in),
    
    .reg_filtdec(reg_filtdec),
    .reg_filten (reg_filten),
    .reg_filtst (reg_filtst),
    .reg_filtsh (reg_filtsh),

    .reg_fifoen  (reg_fifoen),
    .reg_fifoilvl(reg_fifoilvl),
    .fifo_rd     (fifo_rd),

    .fifo_stat (fifo_stat),
    .fifo_lvlup(fifo_lvlup),
    .fifo_full (fifo_full),
    
    .filt_data_out   (filt_data_out),
    .filt_data_update(filt_data_update)
  );



  //-----------------------------------------------------------
  // Comparator unit
  COMP comp
  (
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK),
    .DSDIN  (DSDIN),
    .SDCLK  (SDCLK),
    
    .reg_compdec    (reg_compdec),
    .reg_compen     (reg_compen),
	  .reg_compsen    (reg_compsen),
	  .reg_compst     (reg_compst),
    .reg_compilen   (reg_compilen),
    .reg_compihen   (reg_compihen),
    .reg_complclrflg(reg_complclrflg),
    .reg_comphclrflg(reg_comphclrflg),
	
	  .reg_compltrd(reg_compltrd),
	  .reg_comphtrd(reg_comphtrd),
    
    .comp_data_out   (comp_data_out),
    .comp_data_update(comp_data_update),
	
	  .comp_data_low (comp_data_low),
	  .comp_data_high(comp_data_high)
  );

endmodule
