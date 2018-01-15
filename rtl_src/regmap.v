//===============================================
// Registers map
//===============================================

module REGMAP
(
  input  wire        EXTRSTn,     // external reset
  input  wire        EXTCLK,      // external clock
  input  wire        SYSRSTn,     // system reset
  input  wire        SYSCLK,      // system clock
  input  wire        WR,          // external signal write data
  input  wire        RD,          // external signal read data
  input  wire [15:0] ADDR,        // address bus
  inout  wire [31:0] DATA,        // input/output data bus
  
  // CTL
  output reg         reg_rsten,   // system reset enable
  output reg         reg_clken,   // system clock enable
  
  // DFPARMx
  output wire [15:0] reg_filtdec, // data filter decimation ratio (oversampling ratio)
  output wire [3:0]  reg_inmode,  // input mode
  output wire [7:0]  reg_clkdiv,  // ratio system clock dividing for mode 3
  output wire [1:0]  reg_filten,  // data filter enable
  output wire [1:0]  reg_filtask, // data filter asknewledge enable
  output wire [3:0]  reg_filtst   // data filter structure
  
);

  parameter addr_device_h = 8'h07;

  
  parameter addr_CTL     = 8'h08;
  parameter addr_DFPARMx = 8'h0C;
  
  
  // identification device
  wire this_device_sel;
  assign this_device_sel = (ADDR[15:8] == addr_device_h) && (WR || RD); //FIXME: optimization
  
  // input/output data bus controller
  wire [31:0] WDATA;
  wire [31:0] RDATA;
  assign DATA  = RD ? RDATA : {32{1'bz}};
  assign WDATA = WR ? DATA  : {32{1'b0}};

  

//=====================================================================================
//  CTL    (Control register SDFM)
//=====================================================================================

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
  
//=====================================================================================
//  DFPARMx    (Data filter parameters registers)
//=====================================================================================

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
              
          assign reg_filtdec[7 + i * 8 : i * 8] = reg_filtdecx;
          assign reg_inmode [1 + i * 2 : i * 2] = reg_inmodex;
          assign reg_clkdiv [3 + i * 4 : i * 4] = reg_clkdivx;
          assign reg_filten [i] = reg_filtenx;
          assign reg_filtask[i] = reg_filtaskx;
          assign reg_filtst [1 + i * 2 : i * 2] = reg_filtstx;
        end
    end
  endgenerate
  
  
  
  
  // organization read data
  assign RDATA = reg_CTL_sel ? {{30{1'b0}}, reg_clken, reg_rsten} :
  
                 reg_DFPARMx_sel[0] ? {{8{1'b0}}, 2'b00, reg_filtst[1:0], 2'b00, reg_filtask[0], reg_filten[0], reg_clkdiv[3:0], 2'b00, reg_inmode[1:0], reg_filtdec[7:0] } :  //FIXME
                 
                 
                 reg_DFPARMx_sel[1] ? {{8{1'b0}}, 2'b00, reg_filtst[3:2], 2'b00, reg_filtask[1], reg_filten[1], reg_clkdiv[7:4], 2'b00, reg_inmode[3:2], reg_filtdec[15:8]} :  //FIXME
                 {32{1'b0}};
  
/*
  // CTL
  parameter addr_CTL = 8'h00;
  parameter addr_RSTEN = 0;
  parameter addr_CLKEN = 1;
  parameter addr_CTL_reserved = 2;

  // FPARMx
  parameter addr_FPARM0 = 8'h04;
  parameter addr_FPARM1 = 8'h08;

  //FDATAx
  parameter addr_FDATA0 = 8'h14;
  parameter addr_FDATA1 = 8'h18;

  //==============================================================================================
  // CTL
  //==============================================================================================

  wire CTL_write;
  assign CTL_write = WR && (ADDR == addr_CTL);

  // RSTEN
  reg rstn_enable;
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      rstn_enable <= 1'b0;
    else if(CTL_write)
      rstn_enable <= WDATA[addr_RSTEN];

  // RSTEN
  reg clk_enable;
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      clk_enable <= 1'b0;
    else if(CTL_write)
      clk_enable <= WDATA[addr_CLKEN];

  assign reg_CTL[addr_RSTEN] = rstn_enable;
  assign reg_CTL[addr_CLKEN] = clk_enable;
  assign reg_CTL[addr_CTL_reserved + 29 : addr_CTL_reserved] = 30'h0000_0000;



  //==============================================================================================
  // FPARM
  //==============================================================================================

  wire [1:0] FPARMx_write;
  assign FPARMx_write[0] = WR && (ADDR == addr_FPARM0);
  assign FPARMx_write[1] = WR && (ADDR == addr_FPARM1);

  genvar i;
  generate
    begin : regs_FPARM
      for(i = 0; i < 2; i = i + 1)
        begin : reg_FPARMx
          REG_FPARM reg_fparm
          (
            .EXTRSTn(EXTRSTn),
            .EXTCLK(EXTCLK),
            .WR(FPARMx_write[i]),
            .WDATA(WDATA),
            .reg_FPARM(reg_FPARM[31 + 32 * i : 32 * i])
          );
        end
    end
  endgenerate

  //==============================================================================================
  // FDATA
  //==============================================================================================

  wire [63:0] reg_FDATA;

  wire [1:0] FDATAx_write;
  assign FDATAx_write[0] = data_valid[0];
  assign FDATAx_write[1] = data_valid[1];

  generate
    begin : regs_FDATA
      for(i = 0; i < 2; i = i + 1)
        begin : reg_FDATAx
          REG_FDATA reg_fdata
          (
            .EXTRSTn(EXTRSTn),
            .EXTCLK(EXTCLK),
            .WR(data_valid[i]),
            .WDATA(fifo_data[31 + 32 * i : 32 * i]),
            .reg_FDATA(reg_FDATA[31 + 32 * i : 32 * i])
          );
        end
    end
  endgenerate



  assign RDATA = ADDR == addr_CTL    ? reg_CTL   :
                 ADDR == addr_FPARM0 ? reg_FPARM[31:0 ] :
                 ADDR == addr_FPARM1 ? reg_FPARM[63:32] :
                 ADDR == addr_FDATA0 ? reg_FDATA[31:0 ] :
                 ADDR == addr_FDATA1 ? reg_FDATA[63:32] :
                 {32{1'b0}};
*/
endmodule
