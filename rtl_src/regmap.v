//===============================================
// Registers map
//===============================================

module REGMAP
(
  input  wire        EXTRSTn,   // external reset
  input  wire        EXTCLK,    // external clock
  input  wire        SYSRSTn,   // system reset
  input  wire        SYSCLK,    // system clock
  input  wire        WR,        // external signal write
  input  wire [7:0]  ADDR,      // address bus
  input  wire [31:0] WDATA,     // write data bus
  input  wire [31:0] RDATA,     // read data bus
  
  output reg         reg_rsten, // system reset enable
  output reg         reg_clken  // system clock enable
  
//  input  wire [63:0] fifo_data,
//  input  wire [1:0]  data_valid,
//  output wire [31:0] reg_CTL,
//  output wire [63:0] reg_FPARM
);


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
