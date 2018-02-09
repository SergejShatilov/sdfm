//===============================================
// Comparator unit
//===============================================

module COMP
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        DSDIN,             // direct stream data input
  input  wire        SDCLK,             // sigma-delta clock synchronization

  input  wire [7:0]  reg_compdec,       // comparator data decimation ratio (oversampling ratio)
  input  wire [1:0]  reg_compmod,       // input mode
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



  //===========================================================================================
  //=                             ICU (Input control unit)                                    =
  //===========================================================================================

  wire sd_dsd_in;   // new direct stream data input
  wire sd_clk_in;   // new sigma-delta clock synchronization
  
  
  
  //-----------------------------------------------------------------------
  // generation clock dividing for mode 3
  wire       sysdivclk;
  reg  [6:0] reg_cnt;
  wire [6:0] reg_clkdivt;
  
  assign reg_clkdivt = {1'b0, reg_compdiv, 2'b00} + 7'h03;
  
  assign sysdivclk = (reg_cnt == reg_clkdivt);
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_cnt <= 7'h00;
    else
      reg_cnt <= sysdivclk ? 7'h00 : (reg_cnt + 7'h01);
  
  
  
  //-----------------------------------------------------------------------
  // MUX modes
  assign sd_dsd_in = DSDIN;   //FIXME  
  
  assign sd_clk_in = (reg_compmod == 2'b00) ?  SDCLK :
                     (reg_compmod == 2'b01) ? !SDCLK :
                     sysdivclk; //FIXME
  
  
  
  
  
  //===========================================================================================
  //=                             DCU (Decimation clock unit)                                 =
  //===========================================================================================
  
  wire       osr;
  
  //-----------------------------------------------------------------------
  // generation clock synchronization oversampling ratio
  reg  [7:0] reg_count;
  assign osr = (reg_count == reg_compdec); //FIXME: optimization

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      reg_count <= 8'h00;
    else
      reg_count <= osr ? 8'h00 : (reg_count + 8'h01);   //FIXME: optimization

      
      
      
      
  //===========================================================================================
  //=                             FILT (filter data)                                          =
  //===========================================================================================
  
  
  
  //-----------------------------------------------------------------------
  // filter with infinite impulse response (IIR)
  reg [31:0] CN1;
  reg [31:0] CN2;
  reg [31:0] CN3;

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      CN1 <= 32'h0000_0000;
    else
      CN1 <= sd_dsd_in   ? (CN1 + 32'h0000_0001) :
			 reg_compsen ? (CN1 + 32'hFFFF_FFFF) : (CN1 + 32'h0000_0000);

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
  assign iir_mux = ((reg_compst == 2'b00) || (reg_compst == 2'b10)) ? CN2 : //FIXME: optimization
                    (reg_compst == 2'b01) ? CN1 : CN3;

                    
                    
  //-----------------------------------------------------------------------
  // filter with finite impulse response (FIR)
  reg [31:0] DN0;
  reg [31:0] DN1;
  reg [31:0] DN2;
  reg [31:0] DN3;
  reg [31:0] DN4;
  reg [31:0] DN5;

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
  assign fir_out = (reg_compst == 2'b00) ? QN4 :
                   (reg_compst == 2'b01) ? QN1 :
                   (reg_compst == 2'b10) ? QN2 : QN3;

  //wire [31:0] comp_data;
  assign comp_data_out = fir_out;
  
  
  
  //-----------------------------------------------------------------------
  // generation signal data update
  reg [2:0] reg_osr;
  
  assign comp_data_update = (reg_osr[1:0] == 2'b10) && reg_compen; //FIXME: optimization
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_osr <= 3'b000;
    else
      reg_osr <= {osr, reg_osr[2:1]};
	  
	  
	  
	  
	  
  //===========================================================================================
  //=                              CLU (Comparator low unit)                                  =
  //===========================================================================================
  assign comp_data_low = (comp_data_out < reg_compltrd) && osr;
  
  
  
  
  
  //===========================================================================================
  //=                              CHU (Comparator high unit)                                 =
  //===========================================================================================
  assign comp_data_high = (comp_data_out >= reg_comphtrd) && osr;
  
  
      
endmodule
