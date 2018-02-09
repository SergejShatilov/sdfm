//===============================================
// Filter data unit
//===============================================

module FILT
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock

  input  wire        sd_dsd_in,         // new direct stream data input
  input  wire        sd_clk_in,         // new sigma-delta clock synchronization
  
  input  wire [7:0]  reg_filtdec,       // filter decimation ratio (oversampling ratio)
  input  wire        reg_filten,        // data filter enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  input  wire [4:0]  reg_filtsh,        // value shift bits for data filter
  
  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update   // signal filter data update
);


  
  //===========================================================================================
  //=                             DCU (Decimation clock unit)                                 =
  //===========================================================================================
  
  wire       osr;
  
  //-----------------------------------------------------------------------
  // generation clock synchronization oversampling ratio
  reg  [7:0] reg_count;
  assign osr = (reg_count == reg_filtdec); //FIXME: optimization

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
  assign fir_out = (reg_filtst == 2'b00) ? QN4 :
                   (reg_filtst == 2'b01) ? QN1 :
                   (reg_filtst == 2'b10) ? QN2 : QN3;

  wire [31:0] filt_data;
  assign filt_data = fir_out;
  
  
  
  //-----------------------------------------------------------------------
  // generation signal data update
  
  reg [2:0] reg_osr;
  
  assign filt_data_update = (reg_osr[1:0] == 2'b10) && reg_filten; //FIXME: optimization
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_osr <= 3'b000;
    else
      reg_osr <= {osr, reg_osr[2:1]};
      
      
      
      
  
  //===========================================================================================
  //=                             SHIFT (shift bits for data filter)                          =
  //===========================================================================================
  
  
  
  //-----------------------------------------------------------------------
  // organization shift bits for data filter
  wire [31:0] filt_data_sh;
  
  assign filt_data_sh = (reg_filtsh == 5'h00) ? filt_data[31:0] :                             // 0
                        (reg_filtsh == 5'h01) ? {    filt_data[31],   filt_data[31:1] } :     // 1
                        (reg_filtsh == 5'h02) ? {{ 2{filt_data[31]}}, filt_data[31:2] } :     // 2
                        (reg_filtsh == 5'h03) ? {{ 3{filt_data[31]}}, filt_data[31:3] } :     // 3
                        (reg_filtsh == 5'h04) ? {{ 4{filt_data[31]}}, filt_data[31:4] } :     // 4
                        (reg_filtsh == 5'h05) ? {{ 5{filt_data[31]}}, filt_data[31:5] } :     // 5
                        (reg_filtsh == 5'h06) ? {{ 6{filt_data[31]}}, filt_data[31:6] } :     // 6
                        (reg_filtsh == 5'h07) ? {{ 7{filt_data[31]}}, filt_data[31:7] } :     // 7
                        (reg_filtsh == 5'h08) ? {{ 8{filt_data[31]}}, filt_data[31:8] } :     // 8
                        (reg_filtsh == 5'h09) ? {{ 9{filt_data[31]}}, filt_data[31:9] } :     // 9
                        (reg_filtsh == 5'h0A) ? {{10{filt_data[31]}}, filt_data[31:10]} :     // 10
                        (reg_filtsh == 5'h0B) ? {{11{filt_data[31]}}, filt_data[31:11]} :     // 11
                        (reg_filtsh == 5'h0C) ? {{12{filt_data[31]}}, filt_data[31:12]} :     // 12
                        (reg_filtsh == 5'h0D) ? {{13{filt_data[31]}}, filt_data[31:13]} :     // 13
                        (reg_filtsh == 5'h0E) ? {{14{filt_data[31]}}, filt_data[31:14]} :     // 14
                        (reg_filtsh == 5'h0F) ? {{15{filt_data[31]}}, filt_data[31:15]} :     // 15
                        (reg_filtsh == 5'h10) ? {{16{filt_data[31]}}, filt_data[31:16]} :     // 16
                        (reg_filtsh == 5'h11) ? {{17{filt_data[31]}}, filt_data[31:17]} :     // 17
                        (reg_filtsh == 5'h12) ? {{18{filt_data[31]}}, filt_data[31:18]} :     // 18
                        (reg_filtsh == 5'h13) ? {{19{filt_data[31]}}, filt_data[31:19]} :     // 19
                        (reg_filtsh == 5'h14) ? {{20{filt_data[31]}}, filt_data[31:20]} :     // 20
                        (reg_filtsh == 5'h15) ? {{21{filt_data[31]}}, filt_data[31:21]} :     // 21
                        (reg_filtsh == 5'h16) ? {{22{filt_data[31]}}, filt_data[31:22]} :     // 22
                        (reg_filtsh == 5'h17) ? {{23{filt_data[31]}}, filt_data[31:23]} :     // 23
                        {{24{filt_data[31]}}, filt_data[31:24]};                              // >= 24
  
  assign filt_data_out = reg_filten ? filt_data_sh : 32'h0000_0000;
  

      
endmodule
