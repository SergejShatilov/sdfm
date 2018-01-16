//===============================================
// Registers map
//===============================================

module REGMAP
(
  input  wire        EXTRSTn,           // external reset
  input  wire        EXTCLK,            // external clock
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        WR,                // external signal write data
  input  wire        RD,                // external signal read data
  input  wire [15:0] ADDR,              // address bus
  inout  wire [31:0] DATA,              // input/output data bus
  
  input  wire [63:0] filt_data_out,     // filter data output
  input  wire [1:0]  filt_data_update,  // signal filter data update
  
  // CTL
  output reg         reg_rsten,         // system reset enable
  output reg         reg_clken,         // system clock enable
  
  // DFPARMx
  output wire [15:0] reg_filtdec,       // data filter decimation ratio (oversampling ratio)
  output wire [3:0]  reg_inmode,        // input mode
  output wire [7:0]  reg_clkdiv,        // ratio system clock dividing for mode 3
  output wire [1:0]  reg_filten,        // data filter enable
  output wire [1:0]  reg_filtask,       // data filter asknewledge enable
  output wire [3:0]  reg_filtst,        // data filter structure
  output wire [9:0]  reg_filtsh         // value shift bits for data filter
  
);

  parameter addr_device_h = 8'h07;

  
  parameter addr_CTL     = 8'h08;
  parameter addr_DFPARMx = 8'h0C;
  parameter addr_FDATAx  = 8'h24;
  
  
  // identification device
  wire this_device_sel;
  assign this_device_sel = (ADDR[15:8] == addr_device_h) && (WR || RD); //FIXME: optimization
  
  // input/output data bus controller
  wire [31:0] WDATA;
  wire [31:0] RDATA;
  assign DATA  = RD ? RDATA : {32{1'bz}};
  assign WDATA = WR ? DATA  : {32{1'b0}};

  

  //===========================================================================================
  //  CTL    (Control register SDFM)
  //===========================================================================================
  wire reg_CTL_sel;   // control register select
  assign reg_CTL_sel = (ADDR[7:0] == addr_CTL) && this_device_sel; //FIXME: optimization

  // RSTEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      reg_rsten <= 1'b0;
    else if(reg_CTL_sel && WR)
      reg_rsten <= WDATA[0];
      
  // CLKEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      reg_clken <= 1'b0;
    else if(reg_CTL_sel && WR)
      reg_clken <= WDATA[1];
  
  
  
  //===========================================================================================
  //  DFPARMx    (Data filter parameters registers)
  //===========================================================================================
  wire [1:0] reg_DFPARMx_sel;   // data filter parameters registers select
  
  genvar i;
  generate
    begin : REGS_DFPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : DFPARM

          assign reg_DFPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_DFPARMx) && this_device_sel; //FIXME: optimization
          
          // DOSR
          reg [7:0] reg_filtdecx;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtdecx <= 8'h00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtdecx <= WDATA[7:0];
              
          // MOD
          reg [1:0] reg_inmodex;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_inmodex <= 2'b00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_inmodex <= WDATA[9:8];
              
          // DIV
          reg [3:0] reg_clkdivx;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_clkdivx <= 4'h0;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_clkdivx <= WDATA[15:12];          
              
          // FEN
          reg reg_filtenx;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtenx <= 1'b0;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtenx <= WDATA[16];
              
          // AEN
          reg reg_filtaskx;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtaskx <= 1'b0;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtaskx <= WDATA[17];
              
          // STF
          reg [1:0] reg_filtstx;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtstx <= 2'b00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtstx <= WDATA[21:20];
              
          // SH
          reg [4:0] reg_filtshx;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtshx <= 5'h00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtshx <= WDATA[28:24];
              
          assign reg_filtdec[7 + i * 8 : i * 8] = reg_filtdecx;
          assign reg_inmode [1 + i * 2 : i * 2] = reg_inmodex;
          assign reg_clkdiv [3 + i * 4 : i * 4] = reg_clkdivx;
          assign reg_filten [i] = reg_filtenx;
          assign reg_filtask[i] = reg_filtaskx;
          assign reg_filtst [1 + i * 2 : i * 2] = reg_filtstx;
          assign reg_filtsh [4 + i * 5 : i * 5] = reg_filtshx;
        end
    end
  endgenerate
  
  
  
  //===========================================================================================
  //  FDATAx    (filter data registers)
  //===========================================================================================
  wire [1:0]  reg_FDATAx_sel;   // filter data registers select
  wire [63:0] reg_FDATA;
  
  generate
    begin : REGS_FDATAx
      for(i = 0; i < 2; i = i + 1)
        begin : FDATA

          assign reg_FDATAx_sel[i] = (ADDR[7:0] == i * 4 + addr_FDATAx) && this_device_sel; //FIXME: optimization
          
          reg [31:0] reg_FDATAx;
          
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_FDATAx <= 32'h0000_0000;
            else if(filt_data_update)
              reg_FDATAx <= filt_data_out[31 + i * 32 : i * 32];
         
            assign reg_FDATA[31 + i * 32 : i * 32] = reg_FDATAx;
        end
    end
  endgenerate
  
  
  
  //===========================================================================================
  // organization read data
  assign RDATA = reg_CTL_sel ? {{30{1'b0}}, reg_clken, reg_rsten} :
  
                 reg_DFPARMx_sel[0] ? {3'h0, reg_filtsh[4:0], 2'b00, reg_filtst[1:0], 2'b00, reg_filtask[0], reg_filten[0], reg_clkdiv[3:0], 2'b00, reg_inmode[1:0], reg_filtdec[7:0] } :  //FIXME
                 reg_FDATAx_sel[0]  ? reg_FDATA[31:0] :
                 
                 reg_DFPARMx_sel[1] ? {3'h0, reg_filtsh[9:5], 2'b00, reg_filtst[3:2], 2'b00, reg_filtask[1], reg_filten[1], reg_clkdiv[7:4], 2'b00, reg_inmode[3:2], reg_filtdec[15:8]} :  //FIXME
                 reg_FDATAx_sel[1]  ? reg_FDATA[63:32] :
                 {32{1'b0}};

endmodule
