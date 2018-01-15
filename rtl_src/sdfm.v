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
  wire [3:0]  reg_inmode;   // input mode
  wire [7:0]  reg_clkdiv;   // ratio system clock dividing for mode 3
  wire [1:0]  reg_filten;   // data filter enable
  wire [1:0]  reg_filtask;  // data filter asknewledge enable
  wire [3:0]  reg_filtst;   // data filter structure
  
  
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
  
  // Registers map
  REGMAP regmap
  (
    .EXTRSTn(EXTRSTn),
    .EXTCLK(EXTCLK),
    .SYSRSTn(SYSRSTn),
    .SYSCLK(SYSCLK),
    .WR(WR),
    .RD(RD),
    .ADDR(ADDR),
    .DATA(DATA),
    .reg_rsten(reg_rsten),
    .reg_clken(reg_clken),
    .reg_filtdec(reg_filtdec),
    .reg_inmode(reg_inmode),
    .reg_clkdiv(reg_clkdiv),
    .reg_filten(reg_filten),
    .reg_filtask(reg_filtask),
    .reg_filtst(reg_filtst)
  );


  // Sigma-delta demodulator channels
  genvar i;
  generate
    begin : SD_CHANNELS
      for(i = 0; i < 2; i = i + 1)
        begin : SD_CHANNEL
          CHANNEL channel
          (
            .SYSRSTn(SYSRSTn),
            .SYSCLK(SYSCLK),
            .DSDIN(DSDIN[i]),
            .SDCLK(SDCLK[i]),
            .reg_inmode(reg_inmode[1 + i * 2 : i * 2]),
            .reg_clkdiv(reg_clkdiv[3 + i * 4 : i * 4])
            //.reg_FPARM(reg_FPARM[31 + i * 32 : i * 32]),
            //.fifo_data(fifo_data[31 + i * 32 : i * 32]),
            //.data_valid(data_valid[i])
          );
        end
    end
  endgenerate

endmodule
