//===============================================
// Filter data unit
//===============================================

module FILT
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        sd_dsd_in,         // new direct stream data input
  input  wire        sd_clk_in,         // new sigma-delta clock synchronization
  input  wire        OSR,               // clock synchronization oversampling ratio
  input  wire        reg_filten,        // data filter enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update   // signal filter data update
);

  // filter with infinite impulse response (IIR)
  reg [31:0] CN1;
  reg [31:0] CN2;
  reg [31:0] CN3;

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      CN1 <= 32'h0000_0000;
    else
      CN1 <= sd_dsd_in ? (CN1 + 32'h0000_0001) : (CN1 + 32'hFFFF_FFFF);

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
  assign iir_mux = ((reg_filtst == 2'b00) || (reg_filtst == 2'b10)) ? CN2 : //FIXME: optimization
                    (reg_filtst == 2'b01) ? CN1 : CN3;

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

  always @ (negedge SYSRSTn or posedge OSR)
    if(!SYSRSTn)
      DN0 <= 32'h0000_0000;
    else
      DN0 <= iir_mux;

  always @ (negedge SYSRSTn or posedge OSR)
    if(!SYSRSTn)
      DN1 <= 32'h0000_0000;
    else
      DN1 <= DN0;

  always @ (negedge SYSRSTn or posedge OSR)
    if(!SYSRSTn)
      DN2 <= 32'h0000_0000;
    else
      DN2 <= QN1;

  always @ (negedge SYSRSTn or posedge OSR)
    if(!SYSRSTn)
      DN3 <= 32'h0000_0000;
    else
      DN3 <= QN2;

  always @ (negedge SYSRSTn or posedge OSR)
    if(!SYSRSTn)
      DN4 <= 32'h0000_0000;
    else
      DN4 <= QN2;

  always @ (negedge SYSRSTn or posedge OSR)
    if(!SYSRSTn)
      DN5 <= 32'h0000_0000;
    else
      DN5 <= DN4;

  wire [31:0] fir_out;
  assign fir_out = (reg_filtst == 2'b00) ? QN4 :
                   (reg_filtst == 2'b01) ? QN1 :
                   (reg_filtst == 2'b10) ? QN2 : QN3;

  assign filt_data_out = reg_filten ? fir_out : 32'h0000_0000;
  
  
  // generation signal data update
  reg reg_osr0;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_osr0 <= 1'b0;
    else
      reg_osr0 <= OSR;
  
  reg reg_osr1;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_osr1 <= 1'b0;
    else
      reg_osr1 <= reg_osr0;
      
  reg reg_osr2;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_osr2 <= 1'b0;
    else
      reg_osr2 <= reg_osr1;
      
  assign filt_data_update = (reg_osr1 == 1'b1) && (reg_osr2 == 1'b0) && reg_filten;
  
endmodule
