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


  
  
  //===========================================================================
  // generation clock for mode manchester
  
  reg [1:0] syn_dsd;    // synchronization direct stream data with system clock
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      syn_dsd <= 2'b00;
    else if(reg_inmode == 2'b10)
      syn_dsd <= {DSDIN, syn_dsd[1]};
      
  //wire syn_dsd;
  //assign syn_dsd = 
      
  wire dsd_edge;
  assign dsd_edge = syn_dsd[1] ^ syn_dsd[0];
  
  reg [7:0] dsd_cnt;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      dsd_cnt <= 8'h00;
    else
      dsd_cnt <= dsd_edge ? 8'h00 : (dsd_cnt + 8'h01);
      
  reg [7:0] cnt_min;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      cnt_min <= 8'hFF;
    else if((cnt_min > dsd_cnt) && dsd_edge) //FIXME: optimization
      cnt_min <= dsd_cnt;
      
  reg [7:0] cnt_clk;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      cnt_clk <= 8'h00;
    else
      cnt_clk <= (cnt_clk >= cnt_min) ? 8'h00 : (cnt_clk + 8'h01);
  
  reg strb_cnt_clk;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      strb_cnt_clk <= 1'b0;
    else if(cnt_clk == cnt_min)
      strb_cnt_clk <= !strb_cnt_clk;
  
  
  
  //===========================================================================
  // generation clock dividing for mode 3
  wire       sysdivclk;
  reg  [6:0] reg_cnt;
  wire [6:0] reg_clkdivt;
  assign reg_clkdivt = {1'b0, reg_clkdiv, 2'b00} + 7'h03;
  
  assign sysdivclk = (reg_cnt == reg_clkdivt);
  
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      reg_cnt <= 7'h00;
    else
      reg_cnt <= sysdivclk ? 7'h00 : (reg_cnt + 7'h01);
  
  
  assign sd_dsd_in = (reg_inmode == 2'b10) ? (syn_dsd ^ strb_cnt_clk) :  
                      DSDIN;   //FIXME
  
  
  
  assign sd_clk_in = (reg_inmode == 2'b00) ?  SDCLK       :
                     (reg_inmode == 2'b01) ? !SDCLK       :
                     (reg_inmode == 2'b10) ? strb_cnt_clk :
                     sysdivclk; //FIXME




endmodule 
