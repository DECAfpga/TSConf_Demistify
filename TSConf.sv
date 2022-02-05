//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================




module TSConf_DM
(       
        output        LED,                                              
        output        VGA_HS,
        output        VGA_VS,
        output        AUDIO_L,
        output        AUDIO_R, 
		  output [15:0]  DAC_L, 
		  output [15:0]  DAC_R, 
        input         TAPE_IN,
        input         UART_RX,
        output        UART_TX,
        input         SPI_SCK,
        output        SPI_DO,
        input         SPI_DI,
        input         SPI_SS2,
        input         SPI_SS3,
        input         CONF_DATA0,
        input         CLOCK_27,
        output  [5:0] VGA_R,
        output  [5:0] VGA_G,
        output  [5:0] VGA_B,

		  output [12:0] SDRAM_A,
		  inout  [15:0] SDRAM_DQ,
		  output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nWE,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nCS,
        output  [1:0] SDRAM_BA,
        output        SDRAM_CLK,
        output        SDRAM_CKE,
		  
		  //I2C 
		  inout         I2C_SDA,
		  inout         I2C_SCL,
		  
		  //SRAM
		  output [20:0] SRAM_A,
		  output [7:0] SRAM_DI,
		  input  [7:0] SRAM_DO,
		  output        SRAM_WE,
		  output        SRAM_OE
);


 




`include "build_id.v" 
localparam CONF_STR = {
	"TSConf;;",
	"S0,VHD,Mount virtual SD;",
	"O12,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O34,Stereo mix,None,25%,50%,100%;",
	"OST,General Sound,512KB,1MB,2MB;",
	"OU,CPU Type,NMOS,CMOS;",
	"O67,CPU Speed,3.5MHz,7MHz,14MHz;",
	"O8,CPU Cache,On,Off;",
	"O9A,#7FFD span,128K,128K Auto,1024K,512K;",
	"OLN,ZX Palette,Default,B.black,Light,Pale,Dark,Grayscale,Custom;",
	"OPR,INT Offset,1,2,3,4,5,6,7,0;",
	"OBD,F11 Reset,boot.$C,sys.rom,ROM;",
	"OEF,           bank,TR-DOS,Basic 48,Basic 128,SYS;",
	"OGI,Shift+F11 Reset,ROM,boot.$C,sys.rom;",
	"OJK,           bank,Basic 128,SYS,TR-DOS,Basic 48;",
	"T0,Reset and apply settings;",
	"V,v",`BUILD_DATE
};

wire [27:0] CMOSCfg;

// fix default values
assign CMOSCfg[5:0]  = 0;
assign CMOSCfg[7:6]  = status[7:6];
assign CMOSCfg[8]    = ~status[8];
assign CMOSCfg[10:9] = status[10:9] + 1'd1;
assign CMOSCfg[13:11]= (status[13:11] < 2) ? status[13:11] + 3'd3 : status[13:11] - 3'd2;
assign CMOSCfg[15:14]= status[15:14];
assign CMOSCfg[18:16]= (status[18:16]) ? status[18:16] + 3'd2 : 3'd0;
assign CMOSCfg[20:19]= status[20:19] + 2'd2;
assign CMOSCfg[23:21]= status[23:21];
assign CMOSCfg[24]   = 0;
assign CMOSCfg[27:25]= status[27:25] + 1'd1;


////////////////////   CLOCKS   ///////////////////
wire clk_sys;

pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_sys),
	.c1(CLK_VIDEO)
);


reg ce_28m;
always @(negedge clk_sys) begin
	reg [1:0] div;
	
	div <= div + 1'd1;
	if(div == 2) div <= 0;
	ce_28m <= !div;
end
/////////////////  HPS  ///////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire [31:0] joy_0, joy_1;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire        ypbpr;
wire [64:0] RTC;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        sd_ack_conf;

wire [24:0] ps2_mouse;
wire [10:0] ps2_key;

wire sdhc=1;


mist_io #(.STRLEN($size(CONF_STR)>>3),.PS2DIV(100)) mist_io
(
	.SPI_SCK   (SPI_SCK),
   .CONF_DATA0(CONF_DATA0),
   .SPI_SS2   (SPI_SS2),
   .SPI_DO    (SPI_DO),
   .SPI_DI    (SPI_DI),
	
	.clk_sys(clk_sys),
	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(forced_scandoubler),
   .ypbpr     (ypbpr),
	
	.ioctl_ce(1),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	
  .sd_sdhc(sdhc),
  .sd_conf(0),
  .sd_lba(sd_lba),
  .sd_rd(sd_rd),
  .sd_wr(sd_wr),
  .sd_ack(sd_ack),
  .sd_ack_conf(sd_ack_conf),
  .sd_buff_addr(sd_buff_addr),
  .sd_buff_dout(sd_buff_dout),
  .sd_buff_din(sd_buff_din),
  .sd_buff_wr(sd_buff_wr),
  .img_mounted(img_mounted),
  .img_size(img_size),
	
		
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),
	
	.joystick_0(joy_0), // HPS joy [4:0] {Fire, Up, Down, Left, Right}
	.joystick_1(joy_1)

);
////////////////////  MAIN  //////////////////////
wire [7:0] R,G,B;
wire HBlank,VBlank;
wire VS, HS;
wire ce_vid;

wire reset;
assign LED=~(ioctl_download | sd_act);

wire [20:0] gs_mem_addr;
wire  [7:0] gs_mem_dout;
wire  [7:0] gs_mem_din;
wire        gs_mem_rd;
wire        gs_mem_wr;
wire        gs_mem_ready=1'b1 ;//gs_mem_wr | gs_mem_rd;
reg   [7:0] gs_mem_mask;

always_comb begin
	gs_mem_mask = 0;
	case(status[29:28])
		0: if(gs_mem_addr[20:19]) gs_mem_mask = 8'hFF;
		1: if(gs_mem_addr[20])    gs_mem_mask = 8'hFF;
	 2,3:                        gs_mem_mask = 0;
	endcase
end


assign SRAM_WE      =  ~gs_mem_wr;
assign SRAM_OE      =  1'b0;//~gs_mem_rd;

tsconf tsconf
(
	.clk(clk_sys),
	.ce(ce_28m),

	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_A(SDRAM_A),
	.SDRAM_BA(SDRAM_BA),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_CKE(SDRAM_CKE),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_CLK(SDRAM_CLK),

	.VGA_R(R),
	.VGA_G(G),
	.VGA_B(B),
	.VGA_HS(HS),
	.VGA_VS(VS),
	.VGA_HBLANK(HBlank),
	.VGA_VBLANK(VBlank),
	.VGA_CEPIX(ce_vid),

	.SD_SO(vsdmiso),
	.SD_SI(sdmosi),
	.SD_CLK(sdclk),
	.SD_CS_N(sdss),
	
	.I2C_SCL  (I2C_SCL),
	.I2C_SDA  (I2C_SDA),

	.TAPE_READ (UART_RX),

	.GS_ADDR(SRAM_A),
	.GS_DI(SRAM_DI),
	.GS_DO(SRAM_DO | gs_mem_mask),
	.GS_RD(gs_mem_rd),
	.GS_WR(gs_mem_wr),
	.GS_WAIT(0), 	


	

	.SOUND_L(audio_l_s),
	.SOUND_R(audio_r_s),

	.COLD_RESET(status[0] | reset_img),
	.WARM_RESET(0),
	.RESET_OUT(reset),
	.OUT0(status[30]),

	.CMOSCfg(CMOSCfg),

	.PS2_KEY(ps2_key),
	.PS2_MOUSE(ps2_mouse),
	.joystick(joy_0[5:0] | joy_1[5:0]),

	.loader_addr(ioctl_addr[15:0]),
	.loader_data(ioctl_dout),
	.loader_wr(ioctl_wr && ioctl_download && !ioctl_index && !ioctl_addr[24:16])
);



////////////////  Console  ////////////////////////



wire [15:0] audio_l_s;
wire [15:0] audio_r_s;

dac_dsm2v #(16) dac_l (
   .clock_i      (clk_sys),
   .reset_i      (0      ),
   .dac_i        (audio_l_s),
   .dac_o        (AUDIO_L)
);

dac_dsm2v #(16) dac_r (
   .clock_i      (clk_sys),
   .reset_i      (0      ),
   .dac_i        (audio_r_s),
   .dac_o        (AUDIO_R)
);

assign DAC_L=audio_l_s;
assign DAC_R=audio_r_s;


wire CLK_VIDEO;


/////////////////  VIDEO  /////////////////////////

wire [1:0] scale = status[2:1];


reg ce_pix;
always @(posedge CLK_VIDEO) begin
	reg old_ce;

	old_ce <= ce_vid;
	ce_pix <= ~old_ce & ce_vid;
end

reg VSync, HSync;
always @(posedge CLK_VIDEO) begin
	HSync <= HS;
	if(~HSync & HS) VSync <= VS;
end



video_mixer #(.LINE_LENGTH(720)) video_mixer
(
	.*,

	.ce_pix(ce_pix),
   .ce_pix_actual(ce_pix),
   .scandoubler_disable(scale || forced_scandoubler),
	.hq2x(scale==1),
	.mono(0),
	.scanlines(forced_scandoubler ? 2'b00 : {scale==3, scale==2}),
   .ypbpr_full(0),
   .line_start(0),


	.R(R[7:2]),
	.G(G[7:2]),
	.B(B[7:2])

);


//////////////////   SD   ///////////////////
wire sdclk;
wire sdmosi;
wire vsdmiso;
wire sdss;

reg reset_img;
reg vsd_sel;
always @(posedge clk_sys) begin
	integer to = 0;
	
	if(to) to <= to - 1;
	else reset_img <= 0;

	if(img_mounted) begin
		vsd_sel <= |img_size;
		reset_img <= 1;
		to <= 10000000;
	end
end

sd_card sd_card
(
	.*,
	.clk_spi(clk_sys),

	.sdhc(1),

	.sck(sdclk),
	.ss(~vsd_sel | sdss),
	.mosi(sdmosi),
	.miso(vsdmiso)
);


//wire SD_CS,SD_SCK,SD_MOSI,SD_MISO;
//
//assign SD_CS   = vsd_sel | sdss;
//assign SD_SCK  = sdclk & ~SD_CS;
//assign SD_MOSI = sdmosi & ~SD_CS;

reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= sdmosi;
	old_miso <= vsdmiso;

	sd_act <= 0;
	if(timeout < 1000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ sdmosi) || (old_miso ^ vsdmiso)) timeout <= 0;
end


endmodule