//===============================================
// Registers map
//===============================================

module REGMAP
(
  // general
  input  wire        EXTRSTn,           // external reset
  input  wire        EXTCLK,            // external clock
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        WR,                // external signal write data
  input  wire        RD,                // external signal read data
  input  wire [15:0] ADDR,              // address bus
  inout  wire [31:0] DATA,              // input/output data bus
  output wire        IRQ,               // interrupt request

  // rcu
  output reg         reg_rsten,         // system reset enable
  output reg         reg_clken,         // system clock enable

  // input controls
  output wire [3:0]  reg_inmodx,        // input mode
  output wire [7:0]  reg_indivx,        // ratio system clock dividing for mode 3
  output wire [1:0]  reg_inmfiex,       // modulator failure enable

  input  wire [1:0]  detect_err,        // signal detecter error clock input

  // data filters
  input  wire [63:0] filt_data_outx,    // filter data output
  input  wire [1:0]  filt_data_updatex, // signal filter data update

  output wire [15:0] reg_filtdecx,      // data filter decimation ratio (oversampling ratio)
  output wire [1:0]  reg_filtenx,       // data filter enable
  output wire [1:0]  reg_filtaskx,      // data filter asknewledge enable
  output wire [3:0]  reg_filtstx,       // data filter structure
  output wire [9:0]  reg_filtshx,       // value shift bits for data filter
  
  // comparators
  output wire [15:0] reg_compdecx,      // comparator data decimation ratio (oversampling ratio)
  output wire [1:0]  reg_compenx,       // comparator enable
  output wire [1:0]  reg_compsenx,      // signed data comparator enable
  output wire [3:0]  reg_compstx,       // comparator filter structure
  output wire [1:0]  reg_compilenx,     // enable interrupt comparator for mode low threshold
  output wire [1:0]  reg_compihenx,     // enable interrupt comparator for mode high threshold
  output wire [1:0]  reg_complclrflgx,  // hardware clear flags comparators for mode low threshold
  output wire [1:0]  reg_comphclrflgx,  // hardware clear flags comparators for mode high threshold

  output wire [63:0] reg_compltrdx,     // comparator value low threshold
  output wire [63:0] reg_comphtrdx,     // comparator value high threshold

  input  wire [63:0] comp_data_outx,    // comparator data output
  input  wire [1:0]  comp_data_updatex, // signal comparator data update

  input  wire [1:0]  comp_data_lowx,    // signal comparator data < low threshold
  input  wire [1:0]  comp_data_highx,   // signal comparator data >= high threshold

  // fifo
  output wire [1:0]  reg_fifoenx,       // fifo enable
  output wire [7:0]  reg_fifoilvlx,     // fifo interrupt level
  output wire [1:0]  fifo_rdx,          // signal read FDATA register

  output wire [7:0]  fifo_statx,        // status fifo
  output wire [1:0]  fifo_lvlupx,       // signal level up fifo status
  output wire [1:0]  fifo_fullx         // signal full fifo status

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

  wire [1:0] reg_fifoiffx;
  wire [1:0] reg_fifoiflux;
  
  
  

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
            else if(filt_data_updatex[i])
              flg_af <= 1'b1;

          // MFx
          reg flg_mf;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              flg_mf <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[4 + i])
              flg_mf <= 1'b0;
            else if(detect_err[i] && (reg_filtenx[i] || reg_compenx[i]))
              flg_mf <= 1'b1;

		      // LFx
		      reg flg_lf;
		      always @ (negedge SYSRSTn or posedge SYSCLK)
			      if(!SYSRSTn)
			        flg_lf <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[8 + i])
              flg_lf <= 1'b0;
			      else if(comp_data_updatex[i] && reg_complclrflgx[i])
			        flg_lf <= comp_data_lowx[i];
			      else if(comp_data_updatex[i] && comp_data_lowx[i])
			        flg_lf <= 1'b1;

		      // HFx
		      reg flg_hf;
		      always @ (negedge SYSRSTn or posedge SYSCLK)
			      if(!SYSRSTn)
			        flg_hf <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[12 + i])
              flg_hf <= 1'b0;
			      else if(comp_data_updatex[i] && reg_comphclrflgx[i])
			        flg_hf <= comp_data_highx[i];
			      else if(comp_data_updatex[i] && comp_data_highx[i])
			        flg_hf <= 1'b1;

          // FFx
          reg flg_ff;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              flg_ff <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[16 + i])
              flg_ff <= 1'b0;
            else if(fifo_fullx[i])
              flg_ff <= 1'b1;

          // FLUx
          reg flg_flu;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              flg_flu <= 1'b0;
            else if(reg_IFLGCLR_sel && WR && WDATA[20 + i])
              flg_flu <= 1'b0;
            else if(fifo_lvlupx[i])
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
  assign all_flags = (reg_filtaskx [0] && flg_afx [0]) ||
                     (reg_filtaskx [1] && flg_afx [1]) ||
                     (reg_inmfiex  [0] && flg_mfx [0]) ||
                     (reg_inmfiex  [1] && flg_mfx [1]) ||
                     (reg_compilenx[0] && flg_lfx [0]) ||
	                   (reg_compilenx[1] && flg_lfx [1]) ||
				             (reg_compihenx[0] && flg_hfx [0]) ||
				             (reg_compihenx[1] && flg_hfx [1]) ||
                     (reg_fifoiffx [0] && flg_ffx [0]) ||
                     (reg_fifoiffx [1] && flg_ffx [1]) ||
                     (reg_fifoiflux[0] && flg_flux[0]) ||
                     (reg_compihenx[1] && flg_hfx [1]);

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
  assign reg_CTL_sel = (ADDR[7:0] == addr_CTL) && this_device_sel; //FIXME: optimization

  // RSTEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      reg_rsten <= 1'b0;
    else if(reg_CTL_sel && WR)
      reg_rsten <= WDATA[0];
      
  // CLKEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
      reg_clken <= 1'b0;
    else if(reg_CTL_sel && WR)
      reg_clken <= WDATA[1];
	  
  // MIEN
  always @ (negedge EXTRSTn or posedge EXTCLK)
    if(!EXTRSTn)
	  reg_mien <= 1'b0;
	else if(reg_CTL_sel && WR)
	  reg_mien <= WDATA[4];




  
  //===========================================================================================
  //=                   INPARMx    (Input parameters registers)                               =
  //===========================================================================================
  wire [1:0] reg_INPARMx_sel;   // input parameters registers select

  generate
    begin : REGS_INPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : INPARM

          assign reg_INPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_INPARMx) && this_device_sel; //FIXME: optimization
          
          // MOD
          reg [1:0] reg_inmod;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_inmod <= 2'b00;
            else if(reg_INPARMx_sel[i] && WR)
              reg_inmod <= WDATA[1:0];
              
          // DIV
          reg [3:0] reg_indiv;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_indiv <= 4'h0;
            else if(reg_INPARMx_sel[i] && WR)
              reg_indiv <= WDATA[7:4];

          // MFIE
          reg reg_inmfie;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_inmfie <= 1'b0;
            else if(reg_INPARMx_sel[i] && WR)
              reg_inmfie <= WDATA[8];

          assign reg_inmodx [1 + i * 2 : i * 2] = reg_inmod;
          assign reg_indivx [3 + i * 4 : i * 4] = reg_indiv;
          assign reg_inmfiex[i] = reg_inmfie;
        end
    end
  endgenerate




  
  //===========================================================================================
  //=                   DFPARMx    (Data filter parameters registers)                         =
  //===========================================================================================
  wire [1:0] reg_DFPARMx_sel;   // data filter parameters registers select

  generate
    begin : REGS_DFPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : DFPARM

          assign reg_DFPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_DFPARMx) && this_device_sel; //FIXME: optimization
          
          // DOSR
          reg [7:0] reg_filtdec;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtdec <= 8'h00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtdec <= WDATA[7:0];
              
          // FEN
          reg reg_filten;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filten <= 1'b0;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filten <= WDATA[8];
              
          // AEN
          reg reg_filtask;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtask <= 1'b0;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtask <= WDATA[9];
              
          // ST
          reg [1:0] reg_filtst;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtst <= 2'b00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtst <= WDATA[13:12];
              
          // SH
          reg [4:0] reg_filtsh;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_filtsh <= 5'h00;
            else if(reg_DFPARMx_sel[i] && WR)
              reg_filtsh <= WDATA[20:16];
              
          assign reg_filtdecx[7 + i * 8 : i * 8] = reg_filtdec;
          assign reg_filtenx [i] = reg_filten;
          assign reg_filtaskx[i] = reg_filtask;
          assign reg_filtstx [1 + i * 2 : i * 2] = reg_filtst;
          assign reg_filtshx [4 + i * 5 : i * 5] = reg_filtsh;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                   CPARMx    (Comparator parameters registers)                           =
  //===========================================================================================
  wire [1:0] reg_CPARMx_sel;   // comparator parameters registers select
  
  generate
    begin : REGS_CPARMx
      for(i = 0; i < 2; i = i + 1)
        begin : CPARM

          assign reg_CPARMx_sel[i] = (ADDR[7:0] == i * 4 + addr_CPARMx) && this_device_sel; //FIXME: optimization
          
          // DOSR
          reg [7:0] reg_compdec;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compdec <= 8'h00;
            else if(reg_CPARMx_sel[i] && WR)
              reg_compdec <= WDATA[7:0];
              
          // CEN
          reg reg_compen;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compen <= 1'b0;
            else if(reg_CPARMx_sel[i] && WR)
              reg_compen <= WDATA[8];
			  
		      // SEN
          reg reg_compsen;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compsen <= 1'b0;
            else if(reg_CPARMx_sel[i] && WR)
              reg_compsen <= WDATA[9];
              
		      // ST
          reg [1:0] reg_compst;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compst <= 2'b00;
            else if(reg_CPARMx_sel[i] && WR)
              reg_compst <= WDATA[13:12];
			  
		      // ILEN
          reg reg_compilen;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compilen <= 1'b0;
            else if(reg_CPARMx_sel[i] && WR)
              reg_compilen <= WDATA[16];
			  
		      // IHEN
          reg reg_compihen;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compihen <= 1'b0;
            else if(reg_CPARMx_sel[i] && WR)
              reg_compihen <= WDATA[17];
			  
		      // LCLRFLG
          reg reg_complclrflg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_complclrflg <= 1'b0;
            else if(reg_CPARMx_sel[i] && WR)
              reg_complclrflg <= WDATA[20];
			  
          // HCLRFLG
          reg reg_comphclrflg;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_comphclrflg <= 1'b0;
            else if(reg_CPARMx_sel[i] && WR)
              reg_comphclrflg <= WDATA[21];
              
          assign reg_compdecx    [7 + i * 8 : i * 8] = reg_compdec;
          assign reg_compenx     [i] = reg_compen;
		      assign reg_compsenx    [i] = reg_compsen;
		      assign reg_compstx     [1 + i * 2 : i * 2] = reg_compst;
		      assign reg_compilenx   [i] = reg_compilen;
          assign reg_compihenx   [i] = reg_compihen;
		      assign reg_complclrflgx[i] = reg_complclrflg;
          assign reg_comphclrflgx[i] = reg_comphclrflg;
          
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                   CMPLx    (Comparator value low threshold)                             =
  //===========================================================================================
  wire [1:0] reg_CMPLx_sel;   // comparator value low threshold
  
  generate
    begin : REGS_CMPLx
      for(i = 0; i < 2; i = i + 1)
        begin : CMPL

          assign reg_CMPLx_sel[i] = (ADDR[7:0] == i * 4 + addr_CMPLx) && this_device_sel; //FIXME: optimization
          
          reg [31:0] reg_compltrd;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_compltrd <= 32'h0000_0000;
            else if(reg_CMPLx_sel[i] && WR)
              reg_compltrd <= WDATA;

          assign reg_compltrdx[31 + i * 32 : i * 32] = reg_compltrd;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                   CMPHx    (Comparator value high threshold)                            =
  //===========================================================================================
  wire [1:0] reg_CMPHx_sel;   // comparator value high threshold
  
  generate
    begin : REGS_CMPHx
      for(i = 0; i < 2; i = i + 1)
        begin : CMPH

          assign reg_CMPHx_sel[i] = (ADDR[7:0] == i * 4 + addr_CMPHx) && this_device_sel; //FIXME: optimization
          
          reg [31:0] reg_comphtrd;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_comphtrd <= 32'h0000_0000;
            else if(reg_CMPHx_sel[i] && WR)
              reg_comphtrd <= WDATA;

          assign reg_comphtrdx[31 + i * 32 : i * 32] = reg_comphtrd;
        end
    end
  endgenerate




  
  //===========================================================================================
  //=                   FCTLx      (Fifo parameters registers)                                =
  //===========================================================================================
  wire [1:0] reg_FCTLx_sel;   // fifo parameters registers select
  wire [7:0] reg_fifostatx;

  generate
    begin : REGS_FCTLx
      for(i = 0; i < 2; i = i + 1)
        begin : FCTL

          assign reg_FCTLx_sel[i] = (ADDR[7:0] == i * 4 + addr_FCTLx) && this_device_sel; //FIXME: optimization
          
          // ILVL
          reg [3:0] reg_fifoilvl;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_fifoilvl <= 4'b1111;
            else if(reg_FCTLx_sel[i] && WR)
              reg_fifoilvl <= WDATA[7:4];
              
          // EN
          reg reg_fifoen;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_fifoen <= 1'b0;
            else if(reg_FCTLx_sel[i] && WR)
              reg_fifoen <= WDATA[8];

          // IFF
          reg reg_fifoiff;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_fifoiff <= 1'b0;
            else if(reg_FCTLx_sel[i] && WR)
              reg_fifoiff <= WDATA[12];

          // IFLU
          reg reg_fifoiflu;
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_fifoiflu <= 1'b0;
            else if(reg_FCTLx_sel[i] && WR)
              reg_fifoiflu <= WDATA[13];

          assign reg_fifoilvlx[3 + i * 4 : i * 4] = reg_fifoilvl;
          assign reg_fifoenx  [i] = reg_fifoen;
          assign reg_fifoiffx [i] = reg_fifoiff;
          assign reg_fifoiflux[i] = reg_fifoiflu;
        end
    end
  endgenerate
  




  //===========================================================================================
  //=                       FDATAx    (filter data registers)                                 =
  //===========================================================================================
  wire [1:0]  reg_FDATAx_sel;   // filter data registers select
  wire [63:0] reg_FDATAx;
  
  generate
    begin : REGS_FDATAx
      for(i = 0; i < 2; i = i + 1)
        begin : FDATA

          assign reg_FDATAx_sel[i] = (ADDR[7:0] == i * 4 + addr_FDATAx) && this_device_sel; //FIXME: optimization
          
          reg [31:0] reg_FDATA;
          
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_FDATA <= 32'h0000_0000;
            else if(filt_data_updatex[i])
              reg_FDATA <= filt_data_outx[31 + i * 32 : i * 32];
         
            assign reg_FDATAx[31 + i * 32 : i * 32] = reg_FDATA;

            assign fifo_rdx[i] = reg_FDATAx_sel[i] && RD;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  //=                       CDATAx    (comparator data registers)                                 =
  //===========================================================================================
  wire [1:0]  reg_CDATAx_sel;   // comparator data registers select
  wire [63:0] reg_CDATAx;
  
  generate
    begin : REGS_CDATAx
      for(i = 0; i < 2; i = i + 1)
        begin : CDATA

          assign reg_CDATAx_sel[i] = (ADDR[7:0] == i * 4 + addr_CDATAx) && this_device_sel; //FIXME: optimization
          
          reg [31:0] reg_CDATA;
          
          always @ (negedge SYSRSTn or posedge SYSCLK)
            if(!SYSRSTn)
              reg_CDATA <= 32'h0000_0000;
            else if(comp_data_updatex[i])
              reg_CDATA <= comp_data_outx[31 + i * 32 : i * 32];
         
            assign reg_CDATAx[31 + i * 32 : i * 32] = reg_CDATA;
        end
    end
  endgenerate
  
  
  
  
  
  //===========================================================================================
  // organization read data
  assign RDATA = reg_IFLG_sel ? {flg_irqf, 7'h00,
								                 2'b00, flg_flux, 2'b00, flg_ffx,
								                 2'b00, flg_hfx,  2'b00, flg_lfx,
								                 2'b00, flg_mfx,  2'b00, flg_afx} :
  
  
  
				         reg_CTL_sel ? {{30{1'b0}}, reg_clken, reg_rsten} :

                 reg_INPARMx_sel[0] ? {{23{1'b0}}, reg_inmfiex[0], reg_indivx[3:0], 2'b00, reg_inmodx[1:0]} :
  
  /* 31-24 */    reg_DFPARMx_sel[0] ? {8'h00,
  /* 24-16 */						               3'h0, reg_filtshx[4:0],
  /* 15-08 */						               2'b00, reg_filtstx[1:0], 2'b00, reg_filtaskx[0], reg_filtenx[0],
  /* 07-00 */						               reg_filtdecx[7:0]} :
									   
  /* 31-24 */    reg_CPARMx_sel[0] ? {8'h00,
  /* 23-16 */						              2'b00, reg_comphclrflgx[0], reg_complclrflgx[0], 2'b00, reg_compihenx[0], reg_compilenx[0],
  /* 15-08 */						              2'b00, reg_compstx[1:0], 2'b00, reg_compsenx[0], reg_compenx[0],
  /* 07-00 */						              reg_compdecx[7:0]} :
	
				         reg_CMPLx_sel[0] ? reg_compltrdx[31:0] :
				 
				         reg_CMPHx_sel[0] ? reg_comphtrdx[31:0] :

                 reg_FCTLx_sel[0] ? {{18{1'b0}}, reg_fifoiflux[0], reg_fifoiffx[0], 3'b00, reg_fifoenx[0], reg_fifoilvlx[3:0], fifo_statx[3:0]} :
	
                 reg_FDATAx_sel[0]  ? reg_FDATAx[31:0] :
				 
				         reg_CDATAx_sel[0] ? reg_CDATAx[31:0] :



                 
				         reg_INPARMx_sel[1] ? {{23{1'b0}}, reg_inmfiex[1], reg_indivx[7:4], 2'b00, reg_inmodx[3:2]} :
				 
  /* 31-24 */    reg_DFPARMx_sel[1] ? {8'h00,
  /* 23-16 */  						             3'h0, reg_filtshx[9:5],
  /* 15-08 */                          2'b00, reg_filtstx[3:2], 2'b00, reg_filtaskx[1], reg_filtenx[1],
  /* 07-00 */                          reg_filtdecx[15:8]} :

  /* 31-24 */    reg_CPARMx_sel[1] ? {8'h00,
  /* 23-16 */						              2'b00, reg_comphclrflgx[1], reg_complclrflgx[1], 2'b00, reg_compihenx[1], reg_compilenx[1],
  /* 15-08 */						              2'b00, reg_compstx[3:2], 2'b00, reg_compsenx[1], reg_compenx[1],
  /* 07-00 */						              reg_compdecx[15:8]} :

  				       reg_CMPLx_sel[1] ? reg_compltrdx[63:32] :
				 
				         reg_CMPHx_sel[1] ? reg_comphtrdx[63:32] :

                 reg_FCTLx_sel[1] ? {{18{1'b0}}, reg_fifoiflux[1], reg_fifoiffx[1], 3'b00, reg_fifoenx[1], reg_fifoilvlx[7:4], fifo_statx[7:4]} :
  
			           reg_FDATAx_sel[1]  ? reg_FDATAx[63:32] :
				 
				         reg_CDATAx_sel[1] ? reg_CDATAx[63:32] :
				 
                 {32{1'b0}};

endmodule
