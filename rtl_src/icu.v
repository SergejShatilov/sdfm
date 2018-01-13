//===============================================
// Input control unit
//=============================================== 

module ICU
(
  input  wire       SYSRSTn,      // system reset
  input  wire       SYSCLK,       // system clock
  input  wire       DSDIN,        // direct stream data input
  input  wire       SDCLK,        // sigma-delta clock synchronization
  
  input  wire [1:0] reg_inmode,   // input mode
  input  wire [3:0] reg_clkdiv,   // ratio system clock dividing for mode 3
  
  output wire       sd_dsd_in,    // new direct stream data input
  output wire       sd_clk_in     // new sigma-delta clock synchronization
);


  assign sd_dsd_in = DSDIN;   //FIXME: add modes
  
  assign sd_clk_sd = (reg_inmode == 2'b00) ? SDCLK : 1'b0; //FIXME: add modes




endmodule 
