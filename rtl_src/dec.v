//===============================================
// Decimation unit
//===============================================

module DEC
(
  input  wire        SYSRSTn,    // system reset
  input  wire        sd_clk_in,  // new sigma-delta clock synchronization
  input  wire [7:0]  reg_dec,    // filter decimation ratio (oversampling ratio)
  output wire        OSR         // clock synchronization oversampling ratio
);

  reg [7:0] reg_count;
  
  assign OSR = (reg_count == reg_dec); //FIXME: optimization

  always @ (negedge SYSRSTn or posedge sd_clk_in)
    if(!SYSRSTn)
      reg_count <= 8'h00;
    else
      reg_count <= OSR ? 8'h00 : (reg_count + 8'h01);   //FIXME: optimization

endmodule
