/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: dcu.v
 *
 *  @brief: decimation control unit
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 13.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/ 

module DCU
(
  input  wire       SYSRSTn,    // system reset
  input  wire [7:0] value_dec,  // decimation ratio value
  input  wire       clk_in,     // clock synchronization
  output wire       osr_signal  // oversampling ratio signal
);

  reg  [7:0] reg_count;
  assign osr_signal = (reg_count == value_dec); //FIXME: optimization

  always @ (negedge SYSRSTn or posedge clk_in)
    if(!SYSRSTn)
      reg_count <= 8'h00;
    else
      reg_count <= osr_signal ? 8'h00 : (reg_count + 8'h01);

endmodule
