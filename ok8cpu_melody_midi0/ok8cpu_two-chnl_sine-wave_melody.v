/*
 *   Simple CPU Example -- OK-8 with two-channel sine-wave melody player
 */

module ok8 (
  input clk12, 
  output speaker 
);
reg [23:0] counter;
reg n_reset;
reg Noteout;

always @(posedge clk12) begin
    counter = counter + 1;
end

poweronreset por(.clk(clk12), .n_reset(n_reset));

wire [7:0] spk;
reg [15:0] count = 0;
ok8cpu cpu(
    .clk(counter[18]), 
    .n_reset(n_reset),
    .spk(spk)
);
note_sine_gen note_sine_gen(
    .clk(clk12),
    .f_note(spk),
    .Noteout(Noteout)
);
assign speaker = Noteout;

endmodule

module poweronreset(
	input clk,
	output n_reset);
	reg [7:0] counter;
	always @(posedge clk) begin
		if (counter != 8'b11111111) counter = counter + 8'b1;
	end	
	assign n_reset = counter == 8'b11111111;
endmodule

module ok8cpu(
	input clk, n_reset,
	output reg [7:0] spk
);
reg [7:0] mem[0:8'h3f];
reg [15:0] pc;
reg [7:0] rega, regb, regy, regz;
reg flg;
wire [8:0] op1, op2, op3;
assign op1 = mem[pc];
assign op2 = mem[pc + 1];
assign op3 = mem[pc + 2];
always @(posedge clk, negedge n_reset) begin
    if (!n_reset) begin
        //
        mem[ 0] <= 8'h02; // regy <= melody location
        mem[ 1] <= 8'h0D; // melody location = 13
        //
        mem[ 2] <= 8'h03; // if regy == op2, jump
        mem[ 3] <= 8'h2A; // op2 = 42
        mem[ 4] <= 8'h04; // jump to $00
        mem[ 5] <= 8'h00; //   op2
        mem[ 6] <= 8'h00; //   op3 
        //
        mem[ 7] <= 8'h00; // spk <= mem[regy]
        mem[ 8] <= 8'h01; // regy <= regy + op2 (1)
        mem[ 9] <= 8'h01; // 
        mem[10] <= 8'h04; // jump to $02
        mem[11] <= 8'h00; //   op2
        mem[12] <= 8'h02; //   op3
        //
        //melody: A0 00 80 00 80 00 00 90 00 70 00 70 00 00 61 00 73 00 85 00 93 00 A1 00 A3 00 A5 00 03 00
        mem[13] <= 8'hA0;
        mem[14] <= 8'h00;
        mem[15] <= 8'h80;
        mem[16] <= 8'h00;
        mem[17] <= 8'h80;
        mem[18] <= 8'h00;
        mem[19] <= 8'h00;
        mem[20] <= 8'h90;
        mem[21] <= 8'h00;
        mem[22] <= 8'h70;
        mem[23] <= 8'h00;
        mem[24] <= 8'h70;
        mem[25] <= 8'h00;
        mem[26] <= 8'h00;
        mem[27] <= 8'h61;
        mem[28] <= 8'h00;
        mem[29] <= 8'h73;
        mem[30] <= 8'h00;
        mem[31] <= 8'h85;
        mem[32] <= 8'h00;
        mem[33] <= 8'h93;
        mem[34] <= 8'h00;
        mem[35] <= 8'hA1;
        mem[36] <= 8'h00;
        mem[37] <= 8'hA3;
        mem[38] <= 8'h00;
        mem[39] <= 8'hA5;
        mem[40] <= 8'h00;
        mem[41] <= 8'h03;
        mem[42] <= 8'h00;
        //
        pc  <= 0;
        flg <= 0;
        spk <= 0;

    end else begin
        case (op1)
            8'h00: begin spk <= mem[regy]; flg <= 1; end // current note to speaker
            8'h01: { 0, regy } <= regy + op2; // next position of the melody
            8'h02: begin regy <= op2; flg <= 1; end // setting the beginning of the melody
            8'h03: flg <= regy == op2; // compare:if regy equals to op2
            8'h04: begin pc <= flg ? { op2, op3 } : pc + 3; flg <= 1; end // jump to { op2, op3 }
        endcase
        if (op1 < 4'h1)
            pc <= pc + 1; //only using op1 while 8'h00
        else if (op1 < 4'h4)
            pc <= pc + 2; //using op1 and op2 from 8'h01 to 8'h03
    end
end
endmodule

module note_sine_gen (
    input clk,
    input [7:0] f_note,
    output Noteout
);

reg [7:0] table_index1 = 0;
reg [7:0] table_index2 = 0;
reg [15:0] cnt1 = 0;
reg [15:0] cnt2 = 0;
reg [MSBI:0] sine_table[0:99];
reg [MSBI+2:0] sine;
reg [15:0] f1 = freq[f_note[7:4]]; // format: f_note = {f1,f2} 
reg [15:0] f2 = freq[f_note[3:0]];

parameter MSBI = 7;
parameter slices = 100;
reg [15:0] freq [4'h0:4'hF];

initial begin
    freq[4'h0] = 0;
    //C4
    freq[4'h1] = 458;
    freq[4'h2] = 408;
    freq[4'h3] = 364;
    freq[4'h4] = 344;
    freq[4'h5] = 306;
    //C5
    freq[4'h6] = 229;
    freq[4'h7] = 204;
    freq[4'h8] = 182;
    freq[4'h9] = 172;
    freq[4'hA] = 153;
    // sine wave 100_sample lookup table(0~127)
    sine_table[ 0]=64 ;  sine_table[ 1]=67 ;  sine_table[ 2]=71 ;  sine_table[ 3]=75 ;  sine_table[ 4]=79 ;  sine_table[ 5]=83 ;  sine_table[ 6]=87 ;  sine_table[ 7]=90 ;  sine_table[ 8]=94 ;  sine_table[ 9]=97 ;  
    sine_table[10]=101;  sine_table[11]=104;  sine_table[12]=107;  sine_table[13]=109;  sine_table[14]=112;  sine_table[15]=114;  sine_table[16]=117;  sine_table[17]=119;  sine_table[18]=121;  sine_table[19]=122;  
    sine_table[20]=123;  sine_table[21]=125;  sine_table[22]=125;  sine_table[23]=126;  sine_table[24]=126;  sine_table[25]=127;  sine_table[26]=126;  sine_table[27]=126;  sine_table[28]=125;  sine_table[29]=125;  
    sine_table[30]=123;  sine_table[31]=122;  sine_table[32]=121;  sine_table[33]=119;  sine_table[34]=117;  sine_table[35]=114;  sine_table[36]=112;  sine_table[37]=109;  sine_table[38]=107;  sine_table[39]=104;  
    sine_table[40]=101;  sine_table[41]=97 ;  sine_table[42]=94 ;  sine_table[43]=90 ;  sine_table[44]=87 ;  sine_table[45]=83 ;  sine_table[46]=79 ;  sine_table[47]=75 ;  sine_table[48]=71 ;  sine_table[49]=67 ;  
    sine_table[50]=64 ;  sine_table[51]=60 ;  sine_table[52]=56 ;  sine_table[53]=52 ;  sine_table[54]=48 ;  sine_table[55]=44 ;  sine_table[56]=40 ;  sine_table[57]=37 ;  sine_table[58]=33 ;  sine_table[59]=30 ;  
    sine_table[60]=26 ;  sine_table[61]=23 ;  sine_table[62]=20 ;  sine_table[63]=18 ;  sine_table[64]=15 ;  sine_table[65]=13 ;  sine_table[66]=10 ;  sine_table[67]=8  ;  sine_table[68]=6  ;  sine_table[69]=5  ;  
    sine_table[70]=4  ;  sine_table[71]=2  ;  sine_table[72]=2  ;  sine_table[73]=1  ;  sine_table[74]=1  ;  sine_table[75]=1  ;  sine_table[76]=1  ;  sine_table[77]=1  ;  sine_table[78]=2  ;  sine_table[79]=2  ;  
    sine_table[80]=4  ;  sine_table[81]=5  ;  sine_table[82]=6  ;  sine_table[83]=8  ;  sine_table[84]=10 ;  sine_table[85]=13 ;  sine_table[86]=15 ;  sine_table[87]=18 ;  sine_table[88]=20 ;  sine_table[89]=23 ;  
    sine_table[90]=26 ;  sine_table[91]=30 ;  sine_table[92]=33 ;  sine_table[93]=37 ;  sine_table[94]=40 ;  sine_table[95]=44 ;  sine_table[96]=48 ;  sine_table[97]=52 ;  sine_table[98]=56 ;  sine_table[99]=60 ;  
end

always @(posedge clk)begin
    cnt1 = cnt1 + 1;
    cnt2 = cnt2 + 1;
    // for channel f1
    if (cnt1 == f1)begin
        cnt1 = 0;
        table_index1 = table_index1 + 1;
        if(table_index1 > slices-1)begin
            table_index1 = 0;
        end
    end
    // for channel f2
    if (cnt2 == f2)begin
        cnt2 = 0;
        table_index2 = table_index2 + 1;
        if(table_index2 > slices-1)begin
            table_index2 = 0;
        end
    end

    if (f1 == 0) table_index1 = 0;//set to 0 when no sound
    if (f2 == 0) table_index2 = 0;

    sine = (sine_table[table_index1] + sine_table[table_index2])>>1;
        
end

sigma_delta_dac sdd(
    .clk(clk),
    .DACin(sine),
    .DACout(Noteout)
);

endmodule

module sigma_delta_dac (
    input clk,
    input [MSBI:0] DACin,   //DAC input (excess 2**MSBI)
    output reg DACout   //Average Output feeding analog lowpass
);

parameter MSBI = 7;

reg [MSBI+2:0] DeltaAdder;   //Output of Delta Adder
reg [MSBI+2:0] SigmaAdder;   //Output of Sigma Adder
reg [MSBI+2:0] SigmaLatch;   //Latches output of Sigma Adder
reg [MSBI+2:0] DeltaB;      //B input of Delta Adder

always @ (*)
   DeltaB = {SigmaLatch[MSBI+2], SigmaLatch[MSBI+2]} << (MSBI+1);

always @(*)
   DeltaAdder = DACin*2 + DeltaB;
   
always @(*)
   SigmaAdder = DeltaAdder + SigmaLatch;
   
always @(posedge clk)
    begin
      SigmaLatch <= SigmaAdder;
      DACout <= SigmaLatch[MSBI+2];
   end

endmodule 