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

  // general
  wire SYSRSTn;   // system reset
  wire SYSCLK;    // system clock
  
  // rcu
  wire reg_rsten; // system reset enable
  wire reg_clken; // system clock enable

  // input controls
  wire [3:0]  reg_inmodx;  // input mode
  wire [7:0]  reg_indivx;  // ratio system clock dividing for mode 3

  wire [1:0]  detect_err;  // signal detecter error clock input

  // data filters
  wire [15:0] reg_filtdecx;      // data filter decimation ratio (oversampling ratio)
  wire [1:0]  reg_filtenx;       // data filter enable
  wire [1:0]  reg_filtaskx;      // data filter asknewledge enable
  wire [3:0]  reg_filtstx;       // data filter structure
  wire [9:0]  reg_filtshx;       // value shift bits for data filter
  
  wire [63:0] filt_data_outx;    // filter data output
  wire [1:0]  filt_data_updatex; // signal filter data update
  
  // comparators
  wire [15:0] reg_compdecx;       // comparator data decimation ratio (oversampling ratio)
  wire [3:0]  reg_compmodx;       // input mode
  wire [7:0]  reg_compdivx;       // ratio system clock dividing for mode 3
  wire [1:0]  reg_compenx;        // comparator enable
  wire [1:0]  reg_compsenx;       // signed data comparator enable
  wire [3:0]  reg_compstx;        // comparator filter structure
  wire [1:0]  reg_compilenx;      // enable interrupt comparator for mode low threshold
  wire [1:0]  reg_compihenx;      // enable interrupt comparator for mode high threshold
  wire [1:0]  reg_complclrflgx;   // hardware clear flags comparators for mode low threshold
  wire [1:0]  reg_comphclrflgx;   // hardware clear flags comparators for mode high threshold
  
  wire [63:0] reg_compltrdx;	    // comparator value low threshold
  wire [63:0] reg_comphtrdx;		  // comparator value high threshold
  
  wire [63:0] comp_data_outx;     // comparator data output
  wire [1:0]  comp_data_updatex;  // signal comparator data update

  wire [1:0]  comp_data_lowx;     // signal comparator data < low threshold
  wire [1:0]  comp_data_highx;	  // signal comparator data >= high threshold

  // fifo
  wire [1:0]  reg_fifoenx;   // fifo enable
  wire [7:0]  reg_fifoilvlx; // fifo interrupt level
  wire [1:0]  fifo_rdx;      // signal read FDATA register

  wire [7:0]  fifo_statx;    // status fifo
  wire [1:0]  fifo_lvlupx;   // signal level up fifo status
  wire [1:0]  fifo_fullx;    // signal full fifo status

  
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
    .reg_rsten(reg_rsten),
    .reg_clken(reg_clken),

    // input controls
    .reg_inmodx(reg_inmodx),
    .reg_indivx(reg_indivx),

    .detect_err(detect_err),

    // data filters
    .reg_filtdecx(reg_filtdecx),
    .reg_filtenx (reg_filtenx),
    .reg_filtaskx(reg_filtaskx),
    .reg_filtstx (reg_filtstx),
    .reg_filtshx (reg_filtshx),
    
    .filt_data_outx   (filt_data_outx),
    .filt_data_updatex(filt_data_updatex),

    // comparators
    .reg_compdecx    (reg_compdecx),
    .reg_compenx     (reg_compenx),
	  .reg_compsenx    (reg_compsenx),
	  .reg_compstx     (reg_compstx),
	  .reg_compilenx   (reg_compilenx),
    .reg_compihenx   (reg_compihenx),
	  .reg_complclrflgx(reg_complclrflgx),
    .reg_comphclrflgx(reg_comphclrflgx),

	  .reg_compltrdx(reg_compltrdx),
	  .reg_comphtrdx(reg_comphtrdx),
	 
	  .comp_data_outx   (comp_data_outx),
    .comp_data_updatex(comp_data_updatex),
	
	  .comp_data_lowx (comp_data_lowx),
	  .comp_data_highx(comp_data_highx),

    // fifo
    .reg_fifoenx  (reg_fifoenx),
    .reg_fifoilvlx(reg_fifoilvlx),
    .fifo_rdx     (fifo_rdx),

    .fifo_statx (fifo_statx),
    .fifo_lvlupx(fifo_lvlupx),
    .fifo_fullx (fifo_fullx)
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
            // general
            .SYSRSTn(SYSRSTn),
            .SYSCLK (SYSCLK),
            .DSDIN  (DSDIN[i]),
            .SDCLK  (SDCLK[i]),

            // input control
            .reg_inmod(reg_inmodx[1 + i * 2 : i * 2]),
            .reg_indiv(reg_indivx[3 + i * 4 : i * 4]),

            .detect_err(detect_err[i]),

            // data filter
            .reg_filtdec(reg_filtdecx[7 + i * 8 : i * 8]),
            .reg_filten (reg_filtenx [i]),
            .reg_filtask(reg_filtaskx[i]),
            .reg_filtst (reg_filtstx [1 + i * 2 : i * 2]),
            .reg_filtsh (reg_filtshx [4 + i * 5 : i * 5]),
            
            .filt_data_out   (filt_data_outx   [31 + 32 * i : 32 * i]),
            .filt_data_update(filt_data_updatex[i]),

            // comparator
            .reg_compdec    (reg_compdecx    [7 + i * 8 : i * 8]),
            .reg_compen     (reg_compenx     [i]),
			      .reg_compsen    (reg_compsenx    [i]),
			      .reg_compst     (reg_compstx     [1 + i * 2 : i * 2]),
			      .reg_compilen   (reg_compilenx   [i]),
            .reg_compihen   (reg_compihenx   [i]),
			      .reg_complclrflg(reg_complclrflgx[i]),
            .reg_comphclrflg(reg_comphclrflgx[i]),
			
			      .reg_compltrd(reg_compltrdx[31 + 32 * i : 32 * i]),
			      .reg_comphtrd(reg_comphtrdx[31 + 32 * i : 32 * i]),
			
			      .comp_data_out   (comp_data_outx   [31 + 32 * i : 32 * i]),
            .comp_data_update(comp_data_updatex[i]),
			
			      .comp_data_low (comp_data_lowx [i]),
			      .comp_data_high(comp_data_highx[i]),

            // fifo
            .reg_fifoen  (reg_fifoenx  [i]),
            .reg_fifoilvl(reg_fifoilvlx[3 + 4 * i : 4 * i]),
            .fifo_rd     (fifo_rdx     [i]),

            .fifo_stat (fifo_statx [3 + 4 * i : 4 * i]),
            .fifo_lvlup(fifo_lvlupx[i]),
            .fifo_full (fifo_fullx [i])
          );
        end
    end
  endgenerate
  
  

endmodule
