//===============================================
// Channel sigma-delta
//=============================================== 

module CHANNEL
(
  input  wire       SYSRSTn,      // system reset
  input  wire       SYSCLK,       // system clock
  input  wire       DSDIN,        // direct stream data input
  input  wire       SDCLK,        // sigma-delta clock synchronization

  input  wire [1:0] reg_inmode,   // input mode
  input  wire [3:0] reg_clkdiv    // ratio system clock dividing for mode 3
);

  wire sd_dsd_in;
  wire sd_clk_in;

  
  // Input control unit
  ICU icu
  (
    .SYSRSTn(SYSRSTn),
    .SYSCLK(SYSCLK),
    .DSDIN(DSDIN),
    .SDCLK(SDCLK),
    .reg_inmode(reg_inmode),
    .reg_clkdiv(reg_clkdiv),
    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in)  
  );




/*
  wire OSR;

  wire [31:0] filt_data;
  wire [31:0] shift_data;

  SD_DEC sd_dec
  (
    .SYSRSTn(SYSRSTn),
    .sd_clk_in(sd_clk_in),
    .reg_FPARM(reg_FPARM),
    .OSR(OSR)
  );

  SD_FILT sd_filt
  (
    .SYSRSTn(SYSRSTn),
    .sd_dsd_in(sd_dsd_in),
    .sd_clk_in(sd_clk_in),
    .OSR(OSR),
    .reg_FPARM(reg_FPARM),
    .filt_data_out(filt_data)
  );

  SD_SHIFT sd_shift
  (
    .filt_data(filt_data),
    .reg_FPARM(reg_FPARM),
    .shift_data_out(shift_data)
  );

  reg data_valid_reg;
  assign data_valid = !data_valid_reg && OSR;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      data_valid_reg <= 1'b0;
    else
      data_valid_reg <= OSR;

*/
endmodule
