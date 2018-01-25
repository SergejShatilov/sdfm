//===============================================
// Sigma-delta filter module (Top module)
//===============================================

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

  wire SYSRSTn;   // system reset
  wire SYSCLK;    // system clock
  
  // CTL
  wire reg_rsten; // system reset enable
  wire reg_clken; // system clock enable
  
  // DFPARMx
  wire [15:0] reg_filtdec;  // data filter decimation ratio (oversampling ratio)
  wire [3:0]  reg_filtmode; // input mode
  wire [7:0]  reg_filtdiv;  // ratio system clock dividing for mode 3
  wire [1:0]  reg_filten;   // data filter enable
  wire [1:0]  reg_filtask;  // data filter asknewledge enable
  wire [3:0]  reg_filtst;   // data filter structure
  wire [9:0]  reg_filtsh;   // value shift bits for data filter
  
  wire [63:0] filt_data_out;    // filter data output
  wire [1:0]  filt_data_update; // signal filter data update
  
  // CPARMx
  wire [15:0] reg_compdec;       // comparator data decimation ratio (oversampling ratio)
  wire [3:0]  reg_compmode;      // input mode
  wire [7:0]  reg_compdiv;       // ratio system clock dividing for mode 3
  wire [1:0]  reg_compen;        // comparator enable
  wire [1:0]  reg_compsen;       // signed data comparator enable
  wire [3:0]  reg_compst;        // comparator filter structure
  wire [1:0]  reg_compilen;      // enable interrupt comparator for mode low threshold
  wire [1:0]  reg_compihen;      // enable interrupt comparator for mode high threshold
  wire [1:0]  reg_complclrflg;   // hardware clear flags comparators for mode low threshold
  wire [1:0]  reg_comphclrflg;   // hardware clear flags comparators for mode high threshold
  
  wire [63:0] reg_compltrd;	     // comparator value low threshold
  wire [63:0] reg_comphtrd;		 // comparator value high threshold
  
  wire [63:0] comp_data_out;     // comparator data output
  wire [1:0]  comp_data_update;  // signal comparator data update

  wire [1:0]  comp_data_low;     // signal comparator data < low threshold
  wire [1:0]  comp_data_high;	 // signal comparator data >= high threshold
  

  
  //===========================================================================================
  // Reset and clock unit
  RCU rcu
  (
    .EXTRSTn  (EXTRSTn),
    .EXTCLK   (EXTCLK),
    .reg_rsten(reg_rsten),
    .reg_clken(reg_clken),
    .SYSRSTn  (SYSRSTn),
    .SYSCLK   (SYSCLK)
  );
  
  
  
  //===========================================================================================
  // Registers map
  REGMAP regmap
  (
    .EXTRSTn(EXTRSTn),
    .EXTCLK (EXTCLK),
    .SYSRSTn(SYSRSTn),
    .SYSCLK (SYSCLK),
    .WR     (WR),
    .RD     (RD),
    .ADDR   (ADDR),
    .DATA   (DATA),

    .reg_rsten(reg_rsten),
    .reg_clken(reg_clken),
    
    .reg_filtdec (reg_filtdec),
    .reg_filtmode(reg_filtmode),
    .reg_filtdiv (reg_filtdiv),
    .reg_filten  (reg_filten),
    .reg_filtask (reg_filtask),
    .reg_filtst  (reg_filtst),
    .reg_filtsh  (reg_filtsh),
    
    .filt_data_out   (filt_data_out),
    .filt_data_update(filt_data_update),
    
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
	.comp_data_high(comp_data_high),
	
	.irq(IRQ)
  );

  
  
  //===========================================================================================
  // Sigma-delta demodulator channels
  genvar i;
  generate
    begin : SD_CHANNELS
      for(i = 0; i < 2; i = i + 1)
        begin : SD_CHANNEL
          CHANNEL channel
          (
            .SYSRSTn(SYSRSTn),
            .SYSCLK (SYSCLK),
            .DSDIN  (DSDIN[i]),
            .SDCLK  (SDCLK[i]),
            
            .reg_filtdec (reg_filtdec [7 + i * 8 : i * 8]),
            .reg_filtmode(reg_filtmode[1 + i * 2 : i * 2]),
            .reg_filtdiv (reg_filtdiv [3 + i * 4 : i * 4]),
            .reg_filten  (reg_filten  [i]),
            .reg_filtask (reg_filtask [i]),
            .reg_filtst  (reg_filtst  [1 + i * 2 : i * 2]),
            .reg_filtsh  (reg_filtsh  [4 + i * 5 : i * 5]),
            
            .filt_data_out   (filt_data_out   [31 + 32 * i : 32 * i]),
            .filt_data_update(filt_data_update[i]),
            
            .reg_compdec    (reg_compdec    [7 + i * 8 : i * 8]),
            .reg_compmode   (reg_compmode   [1 + i * 2 : i * 2]),
            .reg_compdiv    (reg_compdiv    [3 + i * 4 : i * 4]),
            .reg_compen     (reg_compen     [i]),
			.reg_compsen    (reg_compsen    [i]),
			.reg_compst     (reg_compst     [1 + i * 2 : i * 2]),
			.reg_compilen   (reg_compilen   [i]),
            .reg_compihen   (reg_compihen   [i]),
			.reg_complclrflg(reg_complclrflg[i]),
            .reg_comphclrflg(reg_comphclrflg[i]),
			
			.reg_compltrd(reg_compltrd[31 + 32 * i : 32 * i]),
			.reg_comphtrd(reg_comphtrd[31 + 32 * i : 32 * i]),
			
			.comp_data_out   (comp_data_out   [31 + 32 * i : 32 * i]),
            .comp_data_update(comp_data_update[i]),
			
			.comp_data_low (comp_data_low [i]),
			.comp_data_high(comp_data_high[i])
          );
        end
    end
  endgenerate
  
  

endmodule
