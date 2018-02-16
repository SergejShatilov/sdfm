/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: regmap.v
 *
 *  @brief: register map (bank)
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 15.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module REGMAP
(
  // general
  input  wire        EXTRSTn,   // external reset
  input  wire        EXTCLK,    // external clock
  input  wire        SYSRSTn,   // system reset
  input  wire        SYSCLK,    // system clock
  input  wire        WR,        // external signal write data
  input  wire        RD,        // external signal read data
  input  wire [15:0] ADDR,      // address bus
  inout  wire [31:0] DATA,      // input/output data bus
  output wire        IRQ,       // interrupt request

  // rcu
  output reg         rcu_rsten_reg,   // system reset enable
  output reg         rcu_clken_reg,   // system clock enable

  // input controls
  output wire [3:0]  icu_mod_regx,      // input mode
  output wire [7:0]  icu_div_regx,      // ratio system clock dividing for mode 3
  output wire [1:0]  icu_mfie_regx,     // modulator failure enable
  input  wire [1:0]  icu_err_signalx,   // signal detecter error clock input

  // data filters
  output wire [15:0] dfilt_dec_regx,        // data filter decimation ratio (oversampling ratio)
  output wire [1:0]  dfilt_en_regx,         // data filter enable
  output wire [1:0]  dfilt_ask_regx,        // data filter asknewledge enable
  output wire [3:0]  dfilt_st_regx,         // data filter structure
  output wire [9:0]  dfilt_sh_regx,         // value shift bits for data filter
  input  wire [63:0] dfilt_data_outx,       // filter data output
  input  wire [1:0]  dfilt_update_signalx,  // signal filter data update
  
  // comparators
  output wire [15:0] comp_dec_regx,         // comparator data decimation ratio (oversampling ratio)
  output wire [1:0]  comp_en_regx,          // comparator enable
  output wire [1:0]  comp_signed_regx,      // signed data comparator enable
  output wire [3:0]  comp_st_regx,          // comparator filter structure
  output wire [1:0]  comp_ilen_regx,        // enable interrupt comparator for mode low threshold
  output wire [1:0]  comp_ihen_regx,        // enable interrupt comparator for mode high threshold
  output wire [1:0]  comp_hlflgclr_regx,    // hardware clear flags comparators for mode low threshold
  output wire [1:0]  comp_hhflgclr_regx,    // hardware clear flags comparators for mode high threshold
  output wire [63:0] comp_ltrd_regx,        // comparator value low threshold
  output wire [63:0] comp_htrd_regx,        // comparator value high threshold
  input  wire [63:0] comp_data_outx,        // comparator data output
  input  wire [1:0]  comp_update_signalx,   // signal comparator data update
  input  wire [1:0]  comp_low_signalx,      // signal comparator data < low threshold
  input  wire [1:0]  comp_high_signalx,     // signal comparator data >= high threshold

  // fifo
  output wire [1:0]  fifo_en_regx,          // fifo enable
  output wire [7:0]  fifo_level_regx,       // fifo interrupt level
  output wire [1:0]  fifo_rd_signalx,       // signal read FDATA register
  output wire [7:0]  fifo_statx,            // status fifo
  output wire [1:0]  fifo_levelup_signalx,  // signal level up fifo status
  output wire [1:0]  fifo_full_signalx      // signal full fifo status
);

  parameter addr_device_h = 8'h07;

  parameter addr_IFLG    = 8'h00;
  parameter addr_IFLGCLR = 8'h04;
  parameter addr_CTL     = 8'h08;
  parameter addr_INPARMx = 8'h0C;
  parameter addr_DFPARMx = 8'h14;
  parameter addr_CPARMx  = 8'h1C;
  parameter addr_CMPLx   = 8'h24;
  parameter addr_CMPHx   = 8'h2C;
  parameter addr_FCTLx   = 8'h34;
  parameter addr_FDATAx  = 8'h3C;
  parameter addr_CDATAx  = 8'h44;
  
  
  // identification device
  wire this_device_sel;
  assign this_device_sel = (ADDR[15:8] == addr_device_h) && (WR || RD); //FIXME: optimization
  
  // input/output data bus controller
  wire [31:0] WDATA;
  wire [31:0] RDATA;
  assign DATA  = RD ? RDATA : {32{1'bz}};
  assign WDATA = WR ? DATA  : {32{1'b0}};
  
  // master interrupt enable
  reg reg_mien;

  wire [1:0] fifo_iff_regx;
  wire [1:0] fifo_iflu_regx;
  
  
  

  //===========================================================================================
  //=                        IFLG & IFLGCLR (Interrupt flags)                                 =
  //===========================================================================================
  
  wire reg_IFLG_sel;  // register interrupt flags select
  assign reg_IFLG_sel = (ADDR[7:0] == addr_IFLG) && this_device_sel; //FIXME: optimization
  
  wire reg_IFLGCLR_sel;   // register clear interrupt flags select
  assign reg_IFLGCLR_sel = (ADDR[7:0] == addr_IFLGCLR) && this_device_sel; //FIXME: optimization

  wire [1:0] flg_afx;
  wire [1:0] flg_mfx;
  wire [1:0] flg_lfx;
  wire [1:0] flg_hfx;
  wire [1:0] flg_ffx;
  wire [1:0] flg_flux;
  
  genvar i;
  generate
    begin : IFLG_CHANNELx
      for(i = 0; i < 2; i = i + 1)
        begin : IFLG_CHANNEL

		      // AFx
		      reg flg_af;
		      always @ (negedge SYSRSTn or posedge SYSCLK)
			      if(!SYSRSTn)
			        flg_af <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[i])
              flg_af <= 1'b0;
            else if(dfilt_update_signalx[i])
              flg_af <= 1'b1;

          // MFx
          reg flg_mf;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              flg_mf <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[4 + i])
              flg_mf <= 1'b0;
            else if(icu_err_signalx[i] && (dfilt_en_regx[i] || comp_en_regx[i]))
              flg_mf <= 1'b1;

		      // LFx
		      reg flg_lf;
		      always @ (negedge SYSRSTn or posedge SYSCLK)
			      if(!SYSRSTn)
			        flg_lf <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[8 + i])
              flg_lf <= 1'b0;
			      else if(comp_update_signalx[i] && comp_hlflgclr_regx[i])
			        flg_lf <= comp_low_signalx[i];
			      else if(comp_update_signalx[i] && comp_low_signalx[i])
			        flg_lf <= 1'b1;

		      // HFx
		      reg flg_hf;
		      always @ (negedge SYSRSTn or posedge SYSCLK)
			      if(!SYSRSTn)
			        flg_hf <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[12 + i])
              flg_hf <= 1'b0;
			      else if(comp_update_signalx[i] && comp_hhflgclr_regx[i])
			        flg_hf <= comp_high_signalx[i];
			      else if(comp_update_signalx[i] && comp_high_signalx[i])
			        flg_hf <= 1'b1;

          // FFx
          reg flg_ff;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              flg_ff <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[16 + i])
              flg_ff <= 1'b0;
            else if(fifo_full_signalx[i])
              flg_ff <= 1'b1;

          // FLUx
          reg flg_flu;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              flg_flu <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[20 + i])
              flg_flu <= 1'b0;
            else if(fifo_levelup_signalx[i])
              flg_flu <= 1'b1;

		      assign flg_afx [i] = flg_af;
          assign flg_mfx [i] = flg_mf;
		      assign flg_lfx [i] = flg_lf;
		      assign flg_hfx [i] = flg_hf;
          assign flg_ffx [i] = flg_ff;
          assign flg_flux[i] = flg_flu;
		    end
	  end
  endgenerate
  
  // IRQF
  wire all_flags;
  assign all_flags = (dfilt_ask_regx[0] && flg_afx [0]) ||
                     (dfilt_ask_regx[1] && flg_afx [1]) ||
                     (icu_mfie_regx [0] && flg_mfx [0]) ||
                     (icu_mfie_regx [1] && flg_mfx [1]) ||
                     (comp_ilen_regx[0] && flg_lfx [0]) ||
	                   (comp_ilen_regx[1] && flg_lfx [1]) ||
				             (comp_ihen_regx[0] && flg_hfx [0]) ||
				             (comp_ihen_regx[1] && flg_hfx [1]) ||
                     (fifo_iff_regx [0] && flg_ffx [0]) ||
                     (fifo_iff_regx [1] && flg_ffx [1]) ||
                     (fifo_iflu_regx[0] && flg_flux[0]) ||
                     (fifo_iflu_regx[1] && flg_flux[1]);

  reg flg_irqf;
  always @ (negedge SYSRSTn or posedge SYSCLK)
    if(!SYSRSTn)
	    flg_irqf <= 1'b0;
    else if(reg_IFLGCLR_sel && WR && WDATA[31])
      flg_irqf <= 1'b0;
	  else if(reg_mien && all_flags)
	    flg_irqf <= 1'b1;

  assign IRQ = flg_irqf;
  
  
  
  
  
  //===========================================================================================
  //=                        CTL    (Control register SDFM)                                   =
  //===========================================================================================
  wire reg_CTL_sel;   // control register select
  wire reg_CTL_wr;    // control register write

  assign reg_CTL_sel = (ADDR[7:0] == addr_CTL) && this_device_sel; //FIXME: optimization
  assign reg_CTL_wr  = reg_CTL_sel && WR;
  
  // RSTEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      rcu_rsten_reg <= 1'b0;
    else if(reg_CTL_wr)
      rcu_rsten_reg <= WDATA[0];
      
  // CLKEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      rcu_clken_reg <= 1'b0;
    else if(reg_CTL_wr)
      rcu_clken_reg <= WDATA[1];
	  
  // MIEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
	  reg_mien <= 1'b0;
	else if(reg_CTL_wr)
	  reg_mien <= WDATA[4];




  
  //===========================================================================================
  //=                   INPARMx    (Input parameters registers)                               =
  //===========================================================================================
  wire [1:0] reg_INPARMx_sel;   // input parameters registers select
  wire [1:0] reg_INPARMx_wr;    // input parameters registers write

  generate
    begin : REGS_INPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : INPARM

          assign reg_INPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_INPARMx) && this_device_sel; //FIXME: optimization
          assign reg_INPARMx_wr [i] = reg_INPARMx_sel[i] && WR;
          
          // MOD
          reg [1:0] icu_mod_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              icu_mod_reg <= 2'b00;
            else if(reg_INPARMx_wr[i])
              icu_mod_reg <= WDATA[1:0];
              
          // DIV
          reg [3:0] icu_div_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              icu_div_reg <= 4'h0;
            else if(reg_INPARMx_wr[i])
              icu_div_reg <= WDATA[7:4];

          // MFIE
          reg icu_mfie_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              icu_mfie_reg <= 1'b0;
            else if(reg_INPARMx_wr[i])
              icu_mfie_reg <= WDATA[8];

          assign icu_mod_regx [1 + i * 2 : i * 2] = icu_mod_reg;
          assign icu_div_regx [3 + i * 4 : i * 4] = icu_div_reg;
          assign icu_mfie_regx[i] = icu_mfie_reg;
        end
    end
  endgenerate




  
  //===========================================================================================
  //=                   DFPARMx    (Data filter parameters registers)                         =
  //===========================================================================================
  wire [1:0] reg_DFPARMx_sel;   // data filter parameters registers select
  wire [1:0] reg_DFPARMx_wr;    // data filter parameters registers write

  generate
    begin : REGS_DFPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : DFPARM

          assign reg_DFPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_DFPARMx) && this_device_sel; //FIXME: optimization
          assign reg_DFPARMx_wr [i] = reg_DFPARMx_sel[i] && WR;
          
          // DOSR
          reg [7:0] dfilt_dec_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              dfilt_dec_reg <= 8'h00;
            else if(reg_DFPARMx_wr[i])
              dfilt_dec_reg <= WDATA[7:0];
              
          // FEN
          reg dfilt_en_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              dfilt_en_reg <= 1'b0;
            else if(reg_DFPARMx_wr[i])
              dfilt_en_reg <= WDATA[8];
              
          // AEN
          reg dfilt_ask_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              dfilt_ask_reg <= 1'b0;
            else if(reg_DFPARMx_wr[i])
              dfilt_ask_reg <= WDATA[9];
              
          // ST
          reg [1:0] dfilt_st_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              dfilt_st_reg <= 2'b00;
            else if(reg_DFPARMx_wr[i])
              dfilt_st_reg <= WDATA[13:12];
              
          // SH
          reg [4:0] dfilt_sh_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              dfilt_sh_reg <= 5'h00;
            else if(reg_DFPARMx_wr[i])
              dfilt_sh_reg <= WDATA[20:16];
              
          assign dfilt_dec_regx[7 + i * 8 : i * 8] = dfilt_dec_reg;
          assign dfilt_en_regx [i] = dfilt_en_reg;
          assign dfilt_ask_regx[i] = dfilt_ask_reg;
          assign dfilt_st_regx [1 + i * 2 : i * 2] = dfilt_st_reg;
          assign dfilt_sh_regx [4 + i * 5 : i * 5] = dfilt_sh_reg;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                   CPARMx    (Comparator parameters registers)                           =
  //===========================================================================================
  wire [1:0] reg_CPARMx_sel;  // comparator parameters registers select
  wire [1:0] reg_CPARMx_wr;   // comparator parameters registers write

  generate
    begin : REGS_CPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : CPARM

          assign reg_CPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_CPARMx) && this_device_sel; //FIXME: optimization
          assign reg_CPARMx_wr [i] = reg_CPARMx_sel[i] && WR;
          
          // DOSR
          reg [7:0] comp_dec_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_dec_reg <= 8'h00;
            else if(reg_CPARMx_wr[i])
              comp_dec_reg <= WDATA[7:0];
              
          // CEN
          reg comp_en_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_en_reg <= 1'b0;
            else if(reg_CPARMx_wr[i])
              comp_en_reg <= WDATA[8];
			  
		      // SEN
          reg comp_signed_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_signed_reg <= 1'b0;
            else if(reg_CPARMx_wr[i])
              comp_signed_reg <= WDATA[9];
              
		      // ST
          reg [1:0] comp_st_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_st_reg <= 2'b00;
            else if(reg_CPARMx_wr[i])
              comp_st_reg <= WDATA[13:12];
			  
		      // ILEN
          reg comp_ilen_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_ilen_reg <= 1'b0;
            else if(reg_CPARMx_wr[i])
              comp_ilen_reg <= WDATA[16];
			  
		      // IHEN
          reg comp_ihen_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_ihen_reg <= 1'b0;
            else if(reg_CPARMx_wr[i])
              comp_ihen_reg <= WDATA[17];
			  
		      // HLFLGCLR
          reg comp_hlflgclr_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_hlflgclr_reg <= 1'b0;
            else if(reg_CPARMx_wr[i])
              comp_hlflgclr_reg <= WDATA[20];
			  
          // HHFLGCLR
          reg comp_hhflgclr_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_hhflgclr_reg <= 1'b0;
            else if(reg_CPARMx_wr[i])
              comp_hhflgclr_reg <= WDATA[21];
              
          assign comp_dec_regx     [7 + i * 8 : i * 8] = comp_dec_reg;
          assign comp_en_regx      [i] = comp_en_reg;
		      assign comp_signed_regx  [i] = comp_signed_reg;
		      assign comp_st_regx      [1 + i * 2 : i * 2] = comp_st_reg;
		      assign comp_ilen_regx    [i] = comp_ilen_reg;
          assign comp_ihen_regx    [i] = comp_ihen_reg;
		      assign comp_hlflgclr_regx[i] = comp_hlflgclr_reg;
          assign comp_hhflgclr_regx[i] = comp_hhflgclr_reg;
          
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                   CMPLx    (Comparator value low threshold)                             =
  //===========================================================================================
  wire [1:0] reg_CMPLx_sel;   // comparator value low threshold registers select
  wire [1:0] reg_CMPLx_wr;    // comparator value low threshold registers write
  
  generate
    begin : REGS_CMPLx
      for(i = 0; i < 2; i = i + 1)
        begin : CMPL

          assign reg_CMPLx_sel[i] = (ADDR[7:0] == i * 4 + addr_CMPLx) && this_device_sel; //FIXME: optimization
          assign reg_CMPLx_wr [i] = reg_CMPLx_sel[i] && WR;
          
          reg [31:0] comp_ltrd_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_ltrd_reg <= 32'h0000_0000;
            else if(reg_CMPLx_wr[i])
              comp_ltrd_reg <= WDATA;

          assign comp_ltrd_regx[31 + i * 32 : i * 32] = comp_ltrd_reg;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                   CMPHx    (Comparator value high threshold)                            =
  //===========================================================================================
  wire [1:0] reg_CMPHx_sel;   // comparator value high threshold registers select
  wire [1:0] reg_CMPHx_wr;    // comparator value high threshold registers write
  
  generate
    begin : REGS_CMPHx
      for(i = 0; i < 2; i = i + 1)
        begin : CMPH

          assign reg_CMPHx_sel[i] = (ADDR[7:0] == i * 4 + addr_CMPHx) && this_device_sel; //FIXME: optimization
          assign reg_CMPHx_wr [i] = reg_CMPHx_sel[i] && WR;
          
          reg [31:0] comp_htrd_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_htrd_reg <= 32'h0000_0000;
            else if(reg_CMPHx_wr[i])
              comp_htrd_reg <= WDATA;

          assign comp_htrd_regx[31 + i * 32 : i * 32] = comp_htrd_reg;
        end
    end
  endgenerate




  
  //===========================================================================================
  //=                   FCTLx      (Fifo parameters registers)                                =
  //===========================================================================================
  wire [1:0] reg_FCTLx_sel;   // fifo parameters registers select
  wire [1:0] reg_FCTLx_wr;    // fifo parameters registers write

  generate
    begin : REGS_FCTLx
      for(i = 0; i < 2; i = i + 1)
        begin : FCTL

          assign reg_FCTLx_sel[i] = (ADDR[7:0] == i * 4 + addr_FCTLx) && this_device_sel; //FIXME: optimization
          assign reg_FCTLx_wr [i] = reg_FCTLx_wr[i] && WR;
          
          // ILVL
          reg [3:0] fifo_level_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              fifo_level_reg <= 4'b1111;
            else if(reg_FCTLx_wr[i])
              fifo_level_reg <= WDATA[7:4];
              
          // EN
          reg fifo_en_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              fifo_en_reg <= 1'b0;
            else if(reg_FCTLx_wr[i])
              fifo_en_reg <= WDATA[8];

          // IFF
          reg fifo_iff_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              fifo_iff_reg <= 1'b0;
            else if(reg_FCTLx_wr[i])
              fifo_iff_reg <= WDATA[12];

          // IFLU
          reg fifo_iflu_reg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              fifo_iflu_reg <= 1'b0;
            else if(reg_FCTLx_wr[i])
              fifo_iflu_reg <= WDATA[13];

          assign fifo_level_regx[3 + i * 4 : i * 4] = fifo_level_reg;
          assign fifo_en_regx   [i] = fifo_en_reg;
          assign fifo_iff_regx  [i] = fifo_iff_reg;
          assign fifo_iflu_regx [i] = fifo_iflu_reg;
        end
    end
  endgenerate
  




  //===========================================================================================
  //=                       FDATAx    (filter data registers)                                 =
  //===========================================================================================
  wire [1:0]  reg_FDATAx_sel;   // filter data registers select
  wire [1:0]  reg_FDATAx_rd;    // filter data registers read
  wire [63:0] dfilt_data_regx;
  
  generate
    begin : REGS_FDATAx
      for(i = 0; i < 2; i = i + 1)
        begin : FDATA

          assign reg_FDATAx_sel[i] = (ADDR[7:0] == i * 4 + addr_FDATAx) && this_device_sel; //FIXME: optimization
          assign reg_FDATAx_rd [i] = reg_FDATAx_sel[i] && RD;
          
          reg [31:0] dfilt_data_reg;
          
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              dfilt_data_reg <= 32'h0000_0000;
            else if(dfilt_update_signalx[i])
              dfilt_data_reg <= dfilt_data_outx[31 + i * 32 : i * 32];
         
            assign dfilt_data_regx[31 + i * 32 : i * 32] = dfilt_data_reg;

            assign fifo_rd_signalx[i] = reg_FDATAx_rd[i];
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                       CDATAx    (comparator data registers)                             =
  //===========================================================================================
  wire [1:0]  reg_CDATAx_sel;   // comparator data registers select
  wire [63:0] comp_data_regx;
  
  generate
    begin : REGS_CDATAx
      for(i = 0; i < 2; i = i + 1)
        begin : CDATA

          assign reg_CDATAx_sel[i] = (ADDR[7:0] == i * 4 + addr_CDATAx) && this_device_sel; //FIXME: optimization
          
          reg [31:0] comp_data_reg;
          
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              comp_data_reg <= 32'h0000_0000;
            else if(comp_update_signalx[i])
              comp_data_reg <= comp_data_outx[31 + i * 32 : i * 32];
         
            assign comp_data_regx[31 + i * 32 : i * 32] = comp_data_reg;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  // organization read data
  assign RDATA = reg_IFLG_sel ? {flg_irqf, 7'h00,
								                 2'b00, flg_flux, 2'b00, flg_ffx,
								                 2'b00, flg_hfx,  2'b00, flg_lfx,
								                 2'b00, flg_mfx,  2'b00, flg_afx} :
  
  
  
				         reg_CTL_sel ? {{30{1'b0}}, rcu_clken_reg, rcu_rsten_reg} :

                 reg_INPARMx_sel[0] ? {{23{1'b0}}, icu_mfie_regx[0], icu_div_regx[3:0], 2'b00, icu_mod_regx[1:0]} :
  
  /* 31-24 */    reg_DFPARMx_sel[0] ? {8'h00,
  /* 24-16 */						               3'h0, dfilt_sh_regx[4:0],
  /* 15-08 */						               2'b00, dfilt_st_regx[1:0], 2'b00, dfilt_ask_regx[0], dfilt_en_regx[0],
  /* 07-00 */						               dfilt_dec_regx[7:0]} :
									   
  /* 31-24 */    reg_CPARMx_sel[0] ? {8'h00,
  /* 23-16 */						              2'b00, comp_hhflgclr_regx[0], comp_hlflgclr_regx[0], 2'b00, comp_ihen_regx[0], comp_ihen_regx[0],
  /* 15-08 */						              2'b00, comp_st_regx[1:0], 2'b00, comp_signed_regx[0], comp_en_regx[0],
  /* 07-00 */						              comp_dec_regx[7:0]} :
	
				         reg_CMPLx_sel[0] ? comp_ltrd_regx[31:0] :
				 
				         reg_CMPHx_sel[0] ? comp_htrd_regx[31:0] :

                 reg_FCTLx_sel[0] ? {{18{1'b0}}, fifo_iflu_regx[0], fifo_iff_regx[0], 3'b00, fifo_en_regx[0], fifo_level_regx[3:0], fifo_statx[3:0]} :
	
                 reg_FDATAx_sel[0]  ? dfilt_data_regx[31:0] :
				 
				         reg_CDATAx_sel[0] ? comp_data_regx[31:0] :



                 
				         reg_INPARMx_sel[1] ? {{23{1'b0}}, icu_mfie_regx[1], icu_div_regx[7:4], 2'b00, icu_mod_regx[3:2]} :
				 
  /* 31-24 */    reg_DFPARMx_sel[1] ? {8'h00,
  /* 23-16 */  						             3'h0, dfilt_sh_regx[9:5],
  /* 15-08 */                          2'b00, dfilt_st_regx[3:2], 2'b00, dfilt_ask_regx[1], dfilt_en_regx[1],
  /* 07-00 */                          dfilt_dec_regx[15:8]} :

  /* 31-24 */    reg_CPARMx_sel[1] ? {8'h00,
  /* 23-16 */						              2'b00, comp_hhflgclr_regx[1], comp_hlflgclr_regx[1], 2'b00, comp_ihen_regx[1], comp_ilen_regx[1],
  /* 15-08 */						              2'b00, comp_st_regx[3:2], 2'b00, comp_signed_regx[1], comp_en_regx[1],
  /* 07-00 */						              comp_dec_regx[15:8]} :

  				       reg_CMPLx_sel[1] ? comp_ltrd_regx[63:32] :
				 
				         reg_CMPHx_sel[1] ? comp_htrd_regx[63:32] :

                 reg_FCTLx_sel[1] ? {{18{1'b0}}, fifo_iflu_regx[1], fifo_iff_regx[1], 3'b00, fifo_en_regx[1], fifo_level_regx[7:4], fifo_statx[7:4]} :
  
			           reg_FDATAx_sel[1]  ? dfilt_data_regx[63:32] :
				 
				         reg_CDATAx_sel[1] ? comp_data_regx[63:32] :
				 
                 {32{1'b0}};

endmodule
