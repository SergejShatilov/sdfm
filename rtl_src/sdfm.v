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
  
  wire [63:0] filt_data_out;    // filter data output
  wire [1:0]  filt_data_update; // signal filter data update
  
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
  

  
  //===========================================================================================
  // Reset and clock unit
  RCU rcu
  (
    .EXTRSTn   (EXTRSTn),
    .EXTCLK    (EXTCLK),
    .reg_rsten (reg_rsten),
    .reg_clken (reg_clken),
    .SYSRSTn   (SYSRSTn),
    .SYSCLK    (SYSCLK)
  );
  
  
  
  //===========================================================================================
  // Registers map
  REGMAP regmap
  (
    .EXTRSTn (EXTRSTn),
    .EXTCLK  (EXTCLK),
    .SYSRSTn (SYSRSTn),
    .SYSCLK  (SYSCLK),
    .WR      (WR),
    .RD      (RD),
    .ADDR    (ADDR),
    .DATA    (DATA),
    .filt_data_out    (filt_data_out),
    .filt_data_update (filt_data_update),
    .reg_rsten   (reg_rsten),
    .reg_clken   (reg_clken),
    .reg_filtdec (reg_filtdec),
    .reg_filtmode(reg_filtmode),
    .reg_filtdiv (reg_filtdiv),
    .reg_filten  (reg_filten),
    .reg_filtask (reg_filtask),
    .reg_filtst  (reg_filtst),
    .reg_filtsh  (reg_filtsh)
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
            .SYSRSTn (SYSRSTn),
            .SYSCLK  (SYSCLK),
            .DSDIN   (DSDIN[i]),
            .SDCLK   (SDCLK[i]),
            .reg_filtdec  (reg_filtdec [7 + i * 8 : i * 8]),
            .reg_filtmode (reg_filtmode[1 + i * 2 : i * 2]),
            .reg_filtdiv  (reg_filtdiv [3 + i * 4 : i * 4]),
            .reg_filten   (reg_filten  [i]),
            .reg_filtask  (reg_filtask [i]),
            .reg_filtst   (reg_filtst  [1 + i * 2 : i * 2]),
            .reg_filtsh   (reg_filtsh  [4 + i * 5 : i * 5]),
            .filt_data_out    (filt_data_out   [31 + 32 * i : 32 * i]),
            .filt_data_update (filt_data_update[i])
          );
        end
    end
  endgenerate
  
  

endmodule
