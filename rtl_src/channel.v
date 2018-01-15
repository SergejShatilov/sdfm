//===============================================
// Channel sigma-delta
//=============================================== 

module CHANNEL
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        DSDIN,             // direct stream data input
  input  wire        SDCLK,             // sigma-delta clock synchronization

  // DFPARMx
  input  wire [7:0]  reg_filtdec,       // data filter decimation ratio (oversampling ratio)
  input  wire [1:0]  reg_inmode,        // input mode
  input  wire [3:0]  reg_clkdiv,        // ratio system clock dividing for mode 3
  input  wire        reg_filten,        // data filter enable
  input  wire        reg_filtask,       // data filter asknewledge enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  
  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update   // signal filter data update
);

  wire sd_dsd_in;   // new direct stream data input
  wire sd_clk_in;   // new sigma-delta clock synchronization
  
  wire OSR;         // clock synchronization oversampling ratio
  
  //wire [31:0] filt_data_out;      // filter data output 
  //wire        filt_data_update;   // signal filter data update
  
  // Input control unit
  ICU icu
  (
    .SYSRSTn    (SYSRSTn),
    .SYSCLK     (SYSCLK),
    .DSDIN      (DSDIN),
    .SDCLK      (SDCLK),
    .reg_inmode (reg_inmode),
    .reg_clkdiv (reg_clkdiv),
    .sd_dsd_in  (sd_dsd_in),
    .sd_clk_in  (sd_clk_in)  
  );
  
  // Decimation unit
  DEC dec
  (
    .SYSRSTn   (SYSRSTn),
    .sd_clk_in (sd_clk_in),
    .reg_dec   (reg_filtdec),
    .OSR       (OSR)  
  );
  
  // Filter data unit
  FILT filt
  (
    .SYSRSTn          (SYSRSTn),
    .SYSCLK           (SYSCLK),
    .sd_dsd_in        (sd_dsd_in),
    .sd_clk_in        (sd_clk_in),
    .OSR              (OSR),
    .reg_filten       (reg_filten),
    .reg_filtst       (reg_filtst),
    .filt_data_out    (filt_data_out),
    .filt_data_update (filt_data_update)
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
