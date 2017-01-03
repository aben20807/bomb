module bomb(reset, clock, button, stop, iwanttostep, isBomb, cancel, led, verf, verf1, keypadC, keypadR, dotC, dotR, hex1, hex2, hex3, hex4, hex5, hex6, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B);

input clock, reset, stop, cancel, isBomb, iwanttostep;
input [3:0]button;
input [3:0]keypadC;

output [3:0]keypadR;
output [15:0]dotC;
output [7:0]dotR;
output [6:0]hex1, hex2, hex3, hex4, hex5, hex6;
output [7:0]led;
output verf, verf1;
output VGA_HS, VGA_VS;
output [3:0]VGA_R, VGA_G, VGA_B;

wire VGA_HS, VGA_VS;
wire [3:0]VGA_R, VGA_G, VGA_B;
reg [15:0]dotC;
reg [7:0]dotR;
reg [31:0]cnt1, cnt2, cnt3;//1s, 10k, 0.5s
reg [7:0]led;
reg [3:0]tmp1, tmp2, tmp3, tmp4, tmp5, tmp6;//for timing
reg div_clk_1s, div_clk_10k;//frequency divider
reg twinkle;//frequency divider fo miner targget
reg [3:0]area;
reg [3:0]State,NextState;
reg [3:0]times;
reg [127:0]pos, twink;
reg second;//count if click twice
reg gameover;
reg verf;
wire verf1;
wire [3:0]isMove;
wire [3:0]index;
wire K;
parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6, S7 = 7, S8 = 8;

assign verf1 = verf;

key(.clk(clock), .rst(reset), .Data(index), .keypadRow(keypadR), .keypadCol(keypadC), .KEY(K));
VGA(.clk(clock), .rst(reset), .vga_hs(VGA_HS), .vga_vs(VGA_VS), .vga_r(VGA_R), .vga_g(VGA_G), .vga_b(VGA_B));

/*scan all rows using 10 KHz*/
always @(negedge reset or posedge div_clk_10k)
begin
	if(!reset)
		times=4'b0000;
	else
	begin
		if(times == 8)
			times=0;
		else
			times=times+1;
	end
end

always @(negedge reset or posedge K or posedge cancel)
begin
	if(!reset)
	begin
		pos[127:0] <= 0;
		twink[127:0] <= 0 ;
		second <= 0;
		verf <= 1;
	end
	else
	begin
		if(cancel == 1)
		begin
			if(stop == 1)
			begin
				second <= 0;
				verf <= 1;
			end
		end
		else if(stop == 1)
		begin
			if(second == 0) 
			begin
				second <= 1;
				verf <= ~verf;
			end
			else if(isBomb == 1 && pos[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] != 1 && twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] == 0)//bug2 fixed
			begin
				twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] <= 1;
				second <= 0;
				verf <= ~verf;
			end
			else if(isBomb == 1 && pos[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] != 1 && twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] == 1)//bug2 fixed
			begin
				twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] <= 0;
				second <= 0;
				verf <= ~verf;
			end
			else
			begin
				if(iwanttostep == 1 && twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] == 1)
				begin
					pos[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] <= 1;
					twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] <= 0;
					verf <= ~verf;
					second <= 0;
				end
				else if(twink[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] == 0)
				begin
					pos[16*((index/4)+(State/4)*4)+4*(State%4)+index%4] <= 1;
					verf <= ~verf;
					second <= 0;
				end
				else//bug1 fixed
				begin
					second <= 0;
					verf <= ~verf;
				end
			end
		end
		else
			verf <= 1;
	end
end

always @(times)
begin
	if(!reset)
	begin
		dotC = 16'b0000000000000000;
		dotR = 8'b11111111;
	end
	else
	begin
	
		case(times)
			0:
			begin
				dotR = 8'b01111111;
				dotC = twinkle ? pos[15:0] + twink[15:0] : pos[15:0];
			end
			1:
			begin
				dotR = 8'b10111111;
				dotC = twinkle ? pos[31:16] + twink[31:16] : pos[31:16];
			end
			2:
			begin
				dotR = 8'b11011111;
				dotC = twinkle ? pos[47:32] + twink[47:32] : pos[47:32];
			end
			3:
			begin
				dotR = 8'b11101111;
				dotC = twinkle ? pos[63:48] + twink[63:48] : pos[63:48];
			end
			4:
			begin
				dotR = 8'b11110111;
				dotC = twinkle ? pos[79:64] + twink[79:64] : pos[79:64];
			end
			5:
			begin
				dotR = 8'b11111011;
				dotC = twinkle ? pos[95:80] + twink[95:80] : pos[95:80];
			end
			6:
			begin
				dotR = 8'b11111101;
				dotC = twinkle ? pos[111:96] + twink[111:96] : pos[111:96];
			end
			7:
			begin
				dotR = 8'b11111110;
				dotC = twinkle ? pos[127:112] + twink[127:112] : pos[127:112];
			end
		endcase
	end
end

/*gameover*/
always @(negedge reset or posedge clock or posedge pos[87])//miner
begin
	if(!reset)
	begin
		gameover = 0;
		State = S0;
	end
	else
	begin
		if(pos[87] == 1)
		begin
			gameover = 1;
			State = S8;
		end
		else
			State = NextState;
	end
end
	
/*create 10 KHz*/
always @(negedge reset or posedge clock)
begin
	if( !reset )
	begin
		cnt2 <= 32'd0;
		div_clk_10k <= 1'b0;
	end
	else
	begin
		if( cnt2 == 32'd2500)
		begin
			cnt2 <= 32'd0;
			div_clk_10k <= ~div_clk_10k;
		end
		else
		begin
			cnt2 <= cnt2 + 32'd1;
		end
	end
end

/*create 1 sec*/
always @(negedge reset or posedge clock)
begin
	if( !reset )
	begin
		cnt1 <=32'd0;
		div_clk_1s <= 1'b0;
		cnt3 <=32'd0;
		twinkle <= 1'b0;
	end
	else
	begin
		if( cnt3 == 32'd12500000)
		begin
			twinkle <= ~twinkle;
			cnt3 <= 32'd0;
		end
		else
			cnt3 <= cnt3 + 32'd1;
		if(cnt1 == 32'd25000000)
		begin
			cnt1 <= 32'd0;
			div_clk_1s <= ~div_clk_1s;
		end
		else
		begin
			cnt1 <= cnt1 + 32'd1;
		end
	end
end

/*timing using 1 sec*/
always @(negedge reset or posedge div_clk_1s)
begin
	if(!reset)
	begin
		tmp1 = 0;
		tmp2 = 0;
		tmp3 = 0;
		tmp4 = 0;
		tmp5 = 0;
		tmp6 = 0;
	end
	else
	begin
		if(stop == 1)
		begin
			tmp1 = tmp1+1;
			if(tmp1 == 10)
			begin
				tmp1 = 0;
				tmp2 = tmp2+1;
			end
			if(tmp2 == 6)
			begin
				tmp2 = 0;
				tmp3 = tmp3+1;
			end
			if(tmp3 == 10)
			begin
				tmp3 = 0;
				tmp4 = tmp4+1;
			end
			if(tmp4 == 6)
			begin
				tmp4 = 0;
				tmp5 = tmp5+1;
			end
			if(tmp5 == 10)
			begin
				tmp5 = 0;
				tmp6 = tmp6+1;
			end
		end
		else
		begin
			tmp1 = tmp1;//when pause
		end
	end
end

/*call seven to display time (hh:mm:ss)*/
Seven s1(.sin(tmp1), .sout(hex1));//s
Seven s2(.sin(tmp2), .sout(hex2));//s
Seven s3(.sin(tmp3), .sout(hex3));//m
Seven s4(.sin(tmp4), .sout(hex4));//m
Seven s5(.sin(tmp5), .sout(hex5));//h
Seven s6(.sin(tmp6), .sout(hex6));//h

/*call move to detect if move button is click*/
move(.clk(clock), .rst(reset), .button(button[0]), .LED(isMove[0]));
move(.clk(clock), .rst(reset), .button(button[1]), .LED(isMove[1]));
move(.clk(clock), .rst(reset), .button(button[2]), .LED(isMove[2]));
move(.clk(clock), .rst(reset), .button(button[3]), .LED(isMove[3]));

/*select area after moving*/
always@(posedge isMove[0] or posedge isMove[1] or posedge isMove[2] or posedge isMove[3])
begin
	case(State)//Moore
		S0:
		begin
			if(isMove[0] == 1)
				NextState = S1;
			else if(isMove[2] == 1)
				NextState = S4;
			else
				NextState = S0;
		end
		S1:
		begin
			if(isMove[0] == 1)
				NextState = S2;
			else if(isMove[2] == 1)
				NextState = S5;
			else if(isMove[1] == 1)
				NextState = S0;
			else
				NextState = S1;
		end
		S2:
		begin
			if(isMove[0] == 1)
				NextState = S3;
			else if(isMove[2] == 1)
				NextState = S6;
			else if(isMove[1] == 1)
				NextState = S1;
			else
				NextState = S2;
		end
		S3:
		begin
			if(isMove[2] == 1)
				NextState = S7;
			else if(isMove[1] == 1)
				NextState = S2;
			else
				NextState = S3;
		end
		S4:
		begin
			if(isMove[0] == 1)
				NextState = S5;
			else if(isMove[3] == 1)
				NextState = S0;
			else
				NextState = S4;
		end
		S5:
		begin
			if(isMove[0] == 1)
				NextState = S6;
			else if(isMove[3] == 1)
				NextState = S1;
			else if(isMove[1] == 1)
				NextState = S4;
			else
				NextState = S5;
			end
		S6:
		begin
			if(isMove[0] == 1)
				NextState = S7;
			else if(isMove[3] == 1)
				NextState = S2;
			else if(isMove[1] == 1)
				NextState = S5;
			else 
				NextState = S6;
		end
		S7:
		begin
			if(isMove[1] == 1)
				NextState = S6;
			else if(isMove[3] == 1)
				NextState = S3;
			else
				NextState = S7;
		end
		default:
			NextState = S0;//bug3 fixed
	endcase
end

/*display area by led*/
always@(State)
begin 
	case(State)
		S7:led = 8'b00000001;
		S6:led = 8'b00000010;
		S5:led = 8'b00000100;
		S4:led = 8'b00001000;
		S3:led = 8'b00010000;
		S2:led = 8'b00100000;
		S1:led = 8'b01000000;
		S0:led = 8'b10000000;
		default:led = 8'b11111111;
	endcase
end
endmodule 

/*output number in seven display*/
module Seven(sin, sout);
input [3:0]sin;
output [6:0]sout;
reg [6:0]sout;
always@(sin)
begin
	case(sin)
		4'b 0000:sout=7'b 1000000;
		4'b 0001:sout=7'b 1111001;
		4'b 0010:sout=7'b 0100100;
		4'b 0011:sout=7'b 0110000;
		4'b 0100:sout=7'b 0011001;
		4'b 0101:sout=7'b 0010010;
		4'b 0110:sout=7'b 0000010;
		4'b 0111:sout=7'b 1111000;
		4'b 1000:sout=7'b 0000000;
		4'b 1001:sout=7'b 0010000;
		4'b 1010:sout=7'b 0001000;
		4'b 1011:sout=7'b 0000011;
		4'b 1100:sout=7'b 1000110;
		4'b 1101:sout=7'b 0100001;
		4'b 1110:sout=7'b 0000110;
		4'b 1111:sout=7'b 0001110;
	endcase
end
endmodule

/*move key*/
module move(clk, rst, button, LED);
input clk, rst, button;	
output LED;

reg flagButton;
reg LED;
reg [24:0]delayButton;

always@(posedge clk)
begin
	if(!rst)
	begin
		LED = 1'b0;
		flagButton = 1'b0;
		delayButton = 25'd0;
	end
	else
	begin
		if((!button)&&(!flagButton)) flagButton = 1'b1;
		else if(flagButton)
		begin
			delayButton = delayButton + 1'b1;
			if(delayButton == 25'b1000000000000000000000000)
			begin
				flagButton = 1'b0;
				delayButton = 25'd0;
				LED = 1'b1;
			end
		end
		else LED = 1'b0;
	end
end
endmodule 

/*return index after clicking keypad*/
`define TimeExpire_KEY 32'd3000000//25'b00100000000000000000000000
module key(clk, rst, Data, keypadRow, keypadCol, KEY);
input clk, rst;
input [3:0]keypadCol;

output [3:0]keypadRow;
output [3:0]Data;
output KEY;

reg KEY;
reg [3:0]keypadRow;
reg [3:0]keypadBuf;
reg [24:0]keypadDelay;

SevenSegment seven(.in(keypadBuf), .out(Data));

always@(posedge clk)
begin
	if(!rst)
	begin
		keypadRow = 4'b1110;
		keypadBuf = 4'b0000;
		keypadDelay = 25'd0;
		KEY = 0;
	end
	else
	begin
		if(keypadDelay == `TimeExpire_KEY)
		begin
			keypadDelay = 25'd0;
			case({keypadRow, keypadCol})
				8'b1110_1110 : 
				begin
					keypadBuf = 4'h7;
					KEY = 1;
					end
				8'b1110_1101 : 
				begin
					keypadBuf = 4'h4;
					KEY = 1;
				end
				8'b1110_1011 : 
				begin
					keypadBuf = 4'h1;
					KEY = 1;
				end
				8'b1110_0111 : 
				begin
					keypadBuf = 4'h0;
					KEY = 1;
				end
				8'b1101_1110 : 
				begin
					keypadBuf = 4'h9;
					KEY = 1;
				end
				8'b1101_1101 : 
				begin
					keypadBuf = 4'h6;
					KEY = 1;
				end
				8'b1101_1011 : 
				begin
					keypadBuf = 4'h3;
					KEY = 1;
				end
				8'b1101_0111 : 
				begin
					keypadBuf = 4'hb;
					KEY = 1;
				end
				8'b1011_1110 : 
				begin
					keypadBuf = 4'h8;
					KEY = 1;
				end
				8'b1011_1101 : 
				begin
					keypadBuf = 4'h5;
					KEY = 1;
				end
				8'b1011_1011 : 
				begin
					keypadBuf = 4'h2;
					KEY = 1;
				end
				8'b1011_0111 : 
				begin
					keypadBuf = 4'ha;
					KEY = 1;
				end
				8'b0111_1110 : 
				begin
					keypadBuf = 4'hc;
					KEY = 1;
				end
				8'b0111_1101 : 
				begin
					keypadBuf = 4'hd;
					KEY = 1;
				end
				8'b0111_1011 : 
				begin
					keypadBuf = 4'he;
					KEY = 1;
				end
				8'b0111_0111 : 
				begin
					keypadBuf = 4'hf;
					KEY = 1;
				end
				default     : 
				begin
					keypadBuf = keypadBuf;
					KEY = 0;
				end
			endcase
			case(keypadRow)
				4'b1110 : keypadRow = 4'b1101;
				4'b1101 : keypadRow = 4'b1011;
				4'b1011 : keypadRow = 4'b0111;
				4'b0111 : keypadRow = 4'b1110;
				default: keypadRow = 4'b1110;
			endcase
		end
		else
		begin
			KEY = 0;
			keypadDelay = keypadDelay + 1'b1;
		end
	end
end
endmodule 

/*return number of keypad*/
module SevenSegment(in,out);
input [3:0]in;
output [3:0]out;
reg [3:0]out;
	always@(*)
	begin
		case(in)
			4'h0: out = 12;
			4'h1: out = 13;
			4'h2: out = 9;
			4'h3: out = 5;
			4'h4: out = 14;
			4'h5: out = 10;
			4'h6: out = 6;
			4'h7: out = 15;
			4'h8: out = 11;
			4'h9: out = 7;
			4'ha: out = 8;
			4'hb: out = 4;
			4'hc: out = 3;
			4'hd: out = 2;
			4'he: out = 1;
			4'hf: out = 0;
		endcase
	end
endmodule 

module VGA(clk, rst, vga_hs, vga_vs, vga_r, vga_g, vga_b);

input clk, rst;
output vga_hs, vga_vs;
output [3:0] vga_r, vga_g, vga_b;

reg vga_hs, vga_vs;
reg [3:0] vga_r, vga_g, vga_b;

reg [10:0] counths;
reg [9:0] countvs;
reg [9:0] p_h, p_v;
reg valid;

always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		counths <= 11'd0;
		countvs <= 10'd0;
	end
	else
	begin
		counths <= (counths == 11'd1600) ? 11'd0 : counths + 16'd1;
		countvs <= (countvs == 10'd525) ? 10'd0 : (counths == 11'd1600) ? countvs + 10'd1 : countvs; 
	end
end

always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		vga_hs <= 1'b0;
		vga_vs <= 1'b0;
		valid <= 1'b0;
	end
	else
	begin
		vga_hs <= (counths < 11'd192 || counths > 11'd1568) ? 1'b0 : 1'b1;
		vga_vs <= (countvs < 10'd2 || countvs > 10'd515) ? 1'b0 : 1'b1;
		valid <= (countvs > 10'd35 && countvs < 10'd516 && counths > 11'd288 && counths < 11'd929) ? 1'b1 : 1'b0;
	end
end

always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		vga_r <= 4'd0;
		vga_g <= 4'd0;
		vga_b <= 4'd0;
	end
	else
	begin
		if(valid)
		begin
			if(countvs < 10'd95 && counths < 11'd250)
			begin
				vga_r <= 4'd0;
				vga_g <= 4'd0;
				vga_b <= 4'd15;
			end
			else if(countvs < 10'd155)
			begin
				vga_r <= 4'd0;
				vga_g <= 4'd15;
				vga_b <= 4'd0;
			end
			else if(countvs < 10'd215)
			begin
				vga_r <= 4'd0;
				vga_g <= 4'd15;
				vga_b <= 4'd15;
			end
			else if(countvs < 10'd275)
			begin
				vga_r <= 4'd15;
				vga_g <= 4'd0;
				vga_b <= 4'd0;
			end
			else if(countvs < 10'd335)
			begin
				vga_r <= 4'd15;
				vga_g <= 4'd0;
				vga_b <= 4'd15;
			end
			else if(countvs < 10'd395)
			begin
				vga_r <= 4'd15;
				vga_g <= 4'd15;
				vga_b <= 4'd0;
			end
			else if(countvs < 10'd455)
			begin
				vga_r <= 4'd15;
				vga_g <= 4'd15;
				vga_b <= 4'd15;
			end
			else
			begin
				vga_r <= 4'd0;
				vga_g <= 4'd0;
				vga_b <= 4'd0;
			end
		end
		else
		begin			
			vga_r <= 4'd0;
			vga_g <= 4'd0;
			vga_b <= 4'd0;
		end
	end
end

endmodule
