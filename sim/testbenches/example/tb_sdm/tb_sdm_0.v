
//===============================================
// GENERATOR
//===============================================
real gen_out_0;
real gen_cnt_0;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    begin
      gen_out_0 = 0.0;
      gen_cnt_0 = 0.0;
    end
  else
    gen_out_0 = sin(1000 * $time * 1e-9 * 2.0 * `PI) +
                sin(4000 * $time * 1e-9 * 2.0 * `PI);

   /*begin
      gen_cnt_0 = gen_cnt_0 + 1.0;
      if(gen_cnt_0 == 200000)
        gen_out_0 <= 1.0;
      else if(gen_cnt_0 == 400000)
        gen_out_0 <= -1.0;

    end*/

//===============================================
// MODULATOR
//===============================================

wire feedback_0;
wire SDM_out_0;

//-----------------------------------------------
// Compressor
real compressor_out_0;
real compressor_abs_0;
real compressor_maximum_0;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    begin
      compressor_out_0     = 0.0;
      compressor_abs_0     = 0.0;
      compressor_maximum_0 = 1e-12;
    end
  else
    begin
      compressor_abs_0 = abs(gen_out_0);
      if(compressor_abs_0 > compressor_maximum_0)
        compressor_maximum_0 = compressor_abs_0;
      compressor_out_0 = gen_out_0 / compressor_maximum_0;
    end

//-----------------------------------------------
// Dac1bit
real dac1bit_out_0;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    dac1bit_out_0 = 0.0;
  else
    dac1bit_out_0 = (feedback_0) ? 1.0 : -1.0;

//-----------------------------------------------
// Difference
real difference_out_0;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    difference_out_0 = 0.0;
  else
    difference_out_0 = compressor_out_0 - dac1bit_out_0;

//-----------------------------------------------
// Integrator
real integrator_out_0;
real integrator_pre_0;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    begin
      integrator_out_0 = 0.0;
      integrator_pre_0 = 0.0;
    end
  else
    begin
      integrator_out_0 = (`MODELING_STEP * 2e-9 * `PI * `FSR_0) * difference_out_0 +
                         exp(`MODELING_STEP * (-2e-9) * `PI * `FSR_0) * integrator_pre_0;
      integrator_pre_0 = integrator_out_0;
    end

//-----------------------------------------------
// Comparator
reg comparator_out_0;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    comparator_out_0 <= 1'b0;
  else
    comparator_out_0 <= (integrator_out_0 > 0.0) ? 1'b1 : 1'b0;

//-----------------------------------------------
// Latch
reg latch_out_0;

assign feedback_0 = latch_out_0;
assign SDM_out_0  = latch_out_0;

always @ (negedge MODELING_RSTn or posedge SDCLK_0)
  if(!EXTRSTn)
    latch_out_0 <= 1'b0;
  else
    latch_out_0 <= comparator_out_0;

