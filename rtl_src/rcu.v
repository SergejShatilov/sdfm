//===============================================
// Reset and clock unit
//=============================================== 

module RCU
(
  input  wire EXTRSTn,  // external reset
  input  wire EXTCLK,   // external clock
  input  wire rsten,    // reset enable
  input  wire clken,    // clock enable
  output wire SYSRSTn,  // system reset
  output wire SYSCLK    // system clock
);

  reg sysrstn;
  assign SYSRSTn = sysrstn;

  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      sysrstn <= 1'b0;
    else
      sysrstn <= rsten ? EXTRSTn : 1'b0;

      
  reg clk_latch;
  assign SYSCLK = clk_latch && EXTCLK;

  always @ (EXTCLK or clken)
    if(!EXTCLK)
      clk_latch <= clken;

endmodule
