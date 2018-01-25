//===============================================
// Channel sigma-delta
//=============================================== 

module CHANNEL
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        DSDIN,             // direct stream data input
  input  wire        SDCLK,             // sigma-delta clock synchronization

  // DFPARMx
  input  wire [7:0]  reg_filtdec,       // data filter decimation ratio (oversampling ratio)
  input  wire [1:0]  reg_filtmode,      // input mode
  input  wire [3:0]  reg_filtdiv,       // ratio system clock dividing for mode 3
  input  wire        reg_filten,        // data filter enable
  input  wire        reg_filtask,       // data filter asknewledge enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  input  wire [4:0]  reg_filtsh,        // value shift bits for data filter
  
  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update,  // signal filter data update
  
  // CPARMx
  input  wire [7:0]  reg_compdec,       // comparator data decimation ratio (oversampling ratio)
  input  wire [1:0]  reg_compmode,      // input mode
  input  wire [3:0]  reg_compdiv,       // ratio system clock dividing for mode 3
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
  
  output wire        comp_data_low,		// signal comparator data < low threshold
  output wire        comp_data_high		// signal comparator data >= high threshold
);

  //-----------------------------------------------------------
  // Filter data unit
  FILT filt
  (
    .SYSRSTn (SYSRSTn),
    .SYSCLK  (SYSCLK),
    .DSDIN   (DSDIN),
    .SDCLK   (SDCLK),
    
    .reg_filtdec      (reg_filtdec),
    .reg_filtmode     (reg_filtmode),
    .reg_filtdiv      (reg_filtdiv),
    .reg_filten       (reg_filten),
    .reg_filtst       (reg_filtst),
    .reg_filtsh       (reg_filtsh),
    
    .filt_data_out    (filt_data_out),
    .filt_data_update (filt_data_update)
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
    .reg_compmode   (reg_compmode),
    .reg_compdiv    (reg_compdiv),
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
