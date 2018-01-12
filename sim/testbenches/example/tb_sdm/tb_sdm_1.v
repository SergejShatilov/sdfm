
//===============================================
// GENERATOR
//===============================================
real gen_out_1;
real gen_cnt_1;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    begin
      gen_out_1 = 0.0;
      gen_cnt_1 = 0.0;
    end
  else
    gen_out_1 = sin(2000 * $time * 1e-9 * 2.0 * `PI) +
                sin(4000 * $time * 1e-9 * 2.0 * `PI);

   /*begin
      gen_cnt_1 = gen_cnt_1 + 1.0;
      if(gen_cnt_1 == 200000)
        gen_out_1 <= 1.0;
      else if(gen_cnt_1 == 400000)
        gen_out_1 <= -1.0;

    end*/

//===============================================
// MODULATOR
//===============================================

wire feedback_1;
wire SDM_out_1;

//-----------------------------------------------
// Compressor
real compressor_out_1;
real compressor_abs_1;
real compressor_maximum_1;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    begin
      compressor_out_1     = 0.0;
      compressor_abs_1     = 0.0;
      compressor_maximum_1 = 1e-12;
    end
  else
    begin
      compressor_abs_1 = abs(gen_out_1);
      if(compressor_abs_1 > compressor_maximum_1)
        compressor_maximum_1 = compressor_abs_1;
      compressor_out_1 = gen_out_1 / compressor_maximum_1;
    end

//-----------------------------------------------
// Dac1bit
real dac1bit_out_1;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    dac1bit_out_1 = 0.0;
  else
    dac1bit_out_1 = (feedback_1) ? 1.0 : -1.0;

//-----------------------------------------------
// Difference
real difference_out_1;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    difference_out_1 = 0.0;
  else
    difference_out_1 = compressor_out_1 - dac1bit_out_1;

//-----------------------------------------------
// Integrator
real integrator_out_1;
real integrator_pre_1;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    begin
      integrator_out_1 = 0.0;
      integrator_pre_1 = 0.0;
    end
  else
    begin
      integrator_out_1 = (`MODELING_STEP * 2e-9 * `PI * `FSR_1) * difference_out_1 +
                         exp(`MODELING_STEP * (-2e-9) * `PI * `FSR_1) * integrator_pre_1;
      integrator_pre_1 = integrator_out_1;
    end

//-----------------------------------------------
// Comparator
reg comparator_out_1;

always @ (negedge MODELING_RSTn or posedge MODELING_CLK)
  if(!MODELING_RSTn)
    comparator_out_1 <= 1'b0;
  else
    comparator_out_1 <= (integrator_out_1 > 0.0) ? 1'b1 : 1'b0;

//-----------------------------------------------
// Latch
reg latch_out_1;

assign feedback_1 = latch_out_1;
assign SDM_out_1  = latch_out_1;

always @ (negedge MODELING_RSTn or posedge SDCLK_1)
  if(!EXTRSTn)
    latch_out_1 <= 1'b0;
  else
    latch_out_1 <= comparator_out_1;

