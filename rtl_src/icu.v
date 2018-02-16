//===============================================
// Input control unit
//===============================================

module ICU
(
  input  wire        SYSRSTn,    // system reset
  input  wire        SYSCLK,     // system clock
  input  wire        DSDIN,      // direct stream data input
  input  wire        SDCLK,      // sigma-delta clock synchronization
  
  input  wire [1:0]  mod,  // input mode
  input  wire [3:0]  div,  // ratio system clock dividing for mode 3

  output wire        sd_dsd_in,  // new direct stream data input
  output wire        sd_clk_in,  // new sigma-delta clock synchronization

  output wire        err_signal  // signal detecter error clock input
);



  //-----------------------------------------------------------------------
  // Manchester decoder for mode 2
  reg         mod2_out;
  reg  [2:0]  mod2_synin;
  reg  [15:0] mod2_cnt;
  reg  [15:0] mod2_precnt;
  reg  [15:0] mod2_min;
  reg  [15:0] mod2_max;
  reg  [15:0] mod2_maxcnt;
  reg         mod2_firstfront;
  reg         mod2_capt;
  wire [15:0] mod2_halfmax;
  wire        mod2_minmaxrst;
  wire        mod2_ready;
  wire        mod2_sample;
  wire        mod2_fronts;
  wire        mod2_minwr;
  wire        mod2_maxwr;
  wire        mod2_inistart;
  wire        mod2_rst;
  wire        mod2_err;

  assign mod2_rst = !SYSRSTn || (mod != 2'b10);

  always @ (posedge SYSCLK)
    mod2_synin <= {mod2_synin[1:0], DSDIN};

  assign mod2_fronts = mod2_synin[1] ^^ mod2_synin[2];

  always @ (posedge SYSCLK)  
    if(mod2_rst || mod2_fronts || mod2_minmaxrst)
      mod2_cnt <= 16'h0000;
    else
      mod2_cnt <= mod2_cnt + 16'h0001;

  always @(posedge SYSCLK)  
    if(mod2_rst || mod2_minmaxrst)
      mod2_firstfront <= 1'b0;
    else if(mod2_fronts)
      mod2_firstfront <= 1'b1;
  
  assign mod2_minmaxrst = mod2_rst || (mod2_min > 16'h0000) && (mod2_min != mod2_max) && !mod2_ready;

  assign mod2_minwr = mod2_firstfront && mod2_fronts && (mod2_min == 16'h0000 || mod2_cnt < mod2_min);

  always @ (posedge SYSCLK)  
    if(mod2_minmaxrst)
      mod2_min <= 16'h0000;
    else if(mod2_minwr)
      mod2_min <= mod2_cnt;

  assign mod2_maxwr = mod2_firstfront && mod2_fronts && (mod2_max == 16'h0000 || mod2_cnt > mod2_max);

  always @(posedge SYSCLK)  
    if(mod2_minmaxrst)
      mod2_max <= 16'h0000;
    else if(mod2_maxwr)
      mod2_max <= mod2_cnt;

  assign mod2_halfmax = mod2_max >> 1;

  assign mod2_ready = (mod2_min >= (mod2_halfmax - 2)) &&
                      (mod2_min <= (mod2_halfmax + 2)) &&
                      (mod2_maxcnt <= (mod2_max + 3)) &&
                      mod2_min != mod2_max;

  always @ (posedge SYSCLK)  
    if(mod2_rst || !mod2_ready)
      mod2_capt <= 1'b0;
    else if(mod2_ready && mod2_sample)
      mod2_capt <= 1'b1;

  assign mod2_initstart = !mod2_ready && mod2_maxwr;

  always @ (posedge SYSCLK)
    if(mod2_minmaxrst || mod2_initstart || mod2_fronts && (mod2_maxcnt <= mod2_max + 2) && (mod2_maxcnt >= mod2_max - 2))
      mod2_maxcnt <= 16'h0000;
    else
      mod2_maxcnt <= mod2_maxcnt + 16'h0001;

  assign mod2_sample = mod2_ready && mod2_fronts && (mod2_maxcnt <= mod2_max + 2) && (mod2_maxcnt >= mod2_max - 2);

  always @ (posedge SYSCLK)
    if(mod2_rst)
      mod2_out <= 1'b0;
    else if(mod2_sample)
      mod2_out <= mod2_synin[1];

  assign mod2_err = !mod2_capt && (mod == 2'b10);


  //-----------------------------------------------------------------------
  // generation clock dividing for mode 3
  wire       mod3_clk;
  wire [6:0] mod3_div;
  reg  [6:0] mod3_cnt;

  assign mod3_div = {1'b0, div, 2'b11};
  assign mod3_clk = (mod3_cnt == mod3_div);

  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      mod3_cnt <= 7'h00;
    else
      mod3_cnt <= mod3_clk ? 7'h00 : (mod3_cnt + 7'h01);

  //-----------------------------------------------------------------------
  // detector error input clock

  wire       edge_clk_in;
  reg  [2:0] edge_clk_in_syn;

  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      edge_clk_in_syn <= 2'b00;
    else
      edge_clk_in_syn <= {edge_clk_in_syn[1:0], SDCLK};

  assign edge_clk_in = edge_clk_in_syn[2] ^ edge_clk_in_syn[1];

  reg [7:0] detect_err_cnt;

  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
      detect_err_cnt <= 8'h00;
    else if(edge_clk_in | (mod == 2'b10))
      detect_err_cnt <= 0;
    else if(!detect_err_cnt[7])
      detect_err_cnt <= detect_err_cnt + 8'h01;
  
  assign err_signal = detect_err_cnt[7] | mod2_err;
  
  
  
  //-----------------------------------------------------------------------
  // MUX modes
  assign sd_dsd_in = (mod == 2'b10) ? mod2_out : DSDIN;
  
  assign sd_clk_in = (mod == 2'b00) ?  SDCLK       :
                     (mod == 2'b01) ? !SDCLK       :
                     (mod == 2'b10) ?  mod2_sample : mod3_clk;
      
endmodule