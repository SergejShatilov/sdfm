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
  input  wire [7:0]  ADDR,      // address bus
  inout  wire [31:0] DATA,      // input/output data bus
  output wire        IRQ        // interrupt request
);

  wire SYSRSTn;   // system reset
  wire SYSCLK;    // system clock
  
  reg reg_rsten; // system reset enable   FIXME
  reg reg_clken; // system clock enable   FIXME
  
  always @ (negedge EXTRSTn)    // TEMPORARILY FIXME
    if(!EXTRSTn)
      begin
        reg_clken <= 1;
        reg_rsten <= 1;
      
      end
  
  
  //wire [1:0] sd_dsd_in;
 // wire [1:0] sd_clk_in;

  wire [31:0] WDATA;
  wire [31:0] RDATA;

  assign DATA  = RD ? RDATA : {32{1'bz}};
  assign WDATA = WR ? DATA  : {32{1'b0}};

  //wire [31:0] reg_CTL;
  //wire [63:0] reg_FPARM;

  //wire [63:0] fifo_data;
 // wire [1:0]  data_valid;


  // Reset and clock unit
  RCU rcu
  (
    .EXTRSTn(EXTRSTn),
    .EXTCLK(EXTCLK),
    .reg_rsten(reg_rsten),
    .reg_clken(reg_clken),
    .SYSRSTn(SYSRSTn),
    .SYSCLK(SYSCLK)
  );
  
/*
  SD_REGMAP sd_regmap
  (
    .EXTRSTn(EXTRSTn),
    .EXTCLK(EXTCLK),
    .WR(WR),
    .ADDR(ADDR),
    .WDATA(WDATA),
    .RDATA(RDATA),
    .fifo_data(fifo_data),
    .data_valid(data_valid),
    .reg_CTL(reg_CTL),
    .reg_FPARM(reg_FPARM)
  );


  genvar i;

  generate
    begin : SD_CHANNELS
      for(i = 0; i < 2; i = i + 1)
        begin : SD_CHANNEL
          SD_CHANNEL sd_channel
          (
            .SYSRSTn(SYSRSTn),
            .SYSCLK(SYSCLK),
            .sd_dsd_in(sd_dsd_in[i]),
            .sd_clk_in(sd_clk_in[i]),
            .reg_FPARM(reg_FPARM[31 + i * 32 : i * 32]),
            .fifo_data(fifo_data[31 + i * 32 : i * 32]),
            .data_valid(data_valid[i])
          );
        end
    end
  endgenerate*/

endmodule
