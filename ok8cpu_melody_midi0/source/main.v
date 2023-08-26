/*
 *   OK-8 with melody player
 *   features: two-seperate-sound-channel, midi-0 format melody, system delay(new version)
 */
module ok8 (input clk12, output speaker );

reg [5:0] sg1_note; reg [5:0] sg2_note;
reg [7:0] DACin1;   reg [7:0] DACin2;

reg [23:0] counter;
always @(posedge clk12) begin
    counter = counter + 1; // clk divider
    if (spk[7:6]==2'b00) sg1_note = spk[5:0];
    else if (spk[7:6]==2'b01) sg2_note = spk[5:0];
end

reg n_reset;
poweronreset por(.clk(clk12), .n_reset(n_reset));

reg [7:0] spk;
ok8cpu cpu(.clk(counter[4]), .n_reset(n_reset), .spk(spk));

note_sine_gen channel1(.clk(clk12), .f_note(sg1_note), .noteout(DACin1));

note_sine_gen channel2(.clk(clk12), .f_note(sg2_note), .noteout(DACin2));

sigma_delta_dac sdd(.clk(clk12), .DACin((DACin1 + DACin2)>>1), .DACout(speakerOut));

reg speakerOut;
assign speaker = speakerOut;

endmodule

module poweronreset(input clk, output n_reset);
	reg [7:0] counter;
	always @(posedge clk) if (counter != 8'b11111111) counter = counter + 8'b1;
	assign n_reset = counter == 8'b11111111;
endmodule

module ok8cpu(input clk, n_reset, output reg [7:0] spk);
reg [7:0] mem[0:8'h6f]; reg [15:0] pc;
reg [7:0] rega, regz;   reg [17:0] regy;
reg flg;                wire [8:0] op1, op2;
assign op1 = mem[pc];   assign op2 = mem[pc + 1];

always @(posedge clk, negedge n_reset) begin
    if (!n_reset) begin
        mem[ 0] <= 8'h04;  mem[ 1] <= 8'h10; // rega <= melody location
        mem[ 2] <= 8'h05;  mem[ 3] <= 8'h64; // if rega == 100, jump to $04
        mem[ 4] <= 8'h06;  mem[ 5] <= 8'h04; // 
        mem[ 6] <= 8'h00; // spk = mem[rega] 
        mem[ 7] <= 8'h03; // still note then jump to $0D
        mem[ 8] <= 8'h06; mem[ 9] <= 8'h0D; //
        mem[10] <= 8'h01; // delay 
        mem[11] <= 8'h06; mem[12] <= 8'h0A; // loop back to $0A
        mem[13] <= 8'h02; // inc rega 
        mem[14] <= 8'h06; mem[15] <= 8'h02; // jump to $02
        // melody
        mem[16] <= 8'h0A; mem[17] <= 8'h40; mem[18] <= 8'h82; mem[19] <= 8'h00; mem[20] <= 8'h40; mem[21] <= 8'h81; 
        mem[22] <= 8'h08; mem[23] <= 8'h40; mem[24] <= 8'h82; mem[25] <= 8'h00; mem[26] <= 8'h40; mem[27] <= 8'h81; 
        mem[28] <= 8'h08; mem[29] <= 8'h40; mem[30] <= 8'h82; mem[31] <= 8'h00; mem[32] <= 8'h40; mem[33] <= 8'h83; 
        mem[34] <= 8'h09; mem[35] <= 8'h40; mem[36] <= 8'h82; mem[37] <= 8'h00; mem[38] <= 8'h40; mem[39] <= 8'h81; 
        mem[40] <= 8'h07; mem[41] <= 8'h40; mem[42] <= 8'h82; mem[43] <= 8'h00; mem[44] <= 8'h40; mem[45] <= 8'h81; 
        mem[46] <= 8'h07; mem[47] <= 8'h40; mem[48] <= 8'h82; mem[49] <= 8'h00; mem[50] <= 8'h40; mem[51] <= 8'h83; 
        mem[52] <= 8'h06; mem[53] <= 8'h41; mem[54] <= 8'h82; mem[55] <= 8'h00; mem[56] <= 8'h40; mem[57] <= 8'h81; 
        mem[58] <= 8'h07; mem[59] <= 8'h43; mem[60] <= 8'h82; mem[61] <= 8'h00; mem[62] <= 8'h40; mem[63] <= 8'h81; 
        mem[64] <= 8'h08; mem[65] <= 8'h45; mem[66] <= 8'h82; mem[67] <= 8'h00; mem[68] <= 8'h40; mem[69] <= 8'h81; 
        mem[70] <= 8'h09; mem[71] <= 8'h43; mem[72] <= 8'h82; mem[73] <= 8'h00; mem[74] <= 8'h40; mem[75] <= 8'h81; 
        mem[76] <= 8'h0A; mem[77] <= 8'h41; mem[78] <= 8'h82; mem[79] <= 8'h00; mem[80] <= 8'h40; mem[81] <= 8'h81; 
        mem[82] <= 8'h0A; mem[83] <= 8'h43; mem[84] <= 8'h82; mem[85] <= 8'h00; mem[86] <= 8'h40; mem[87] <= 8'h81; 
        mem[88] <= 8'h0A; mem[89] <= 8'h45; mem[90] <= 8'h82; mem[91] <= 8'h00; mem[92] <= 8'h40; mem[93] <= 8'h81; 
        mem[94] <= 8'h00; mem[95] <= 8'h43; mem[96] <= 8'h82; mem[97] <= 8'h00; mem[98] <= 8'h40; mem[99] <= 8'h83; 
        //
        pc <= 0; flg <= 0; spk <= 0; rega <= 0; regy <= 0; regz <= 0;  
    end else begin
        case (op1)
            8'h00: begin spk <= mem[rega]; flg <= 1; end // current note to rega
            8'h01: begin if (regy==18'h61A8) begin regy = 0; regz = regz + 1; end else begin regy = regy + 1; regz = regz; end
                         if (regz==(mem[rega]-8'h80)) begin regz <= 0; flg = 0; end else begin regz <= regz; flg = 1; end end
            8'h02: begin {0,rega} <= rega + 1; flg <= 1; end // next position of the melody
            8'h03: begin flg  <= (mem[rega]<8'h80); end // if its a note then flg = 1
            8'h04: begin rega <= op2; flg <= 1; end // setting the beginning of the melody
            8'h05: begin flg  <= (rega==op2); end // compare:if rega equals to op2
            8'h06: begin pc   <= flg ? op2 : pc + 2; flg <= 1; end // jump to op2
            8'hff: flg <= 1;
        endcase
        if (op1 < 4'h4) pc <= pc + 1; //only using op1 from 8'h00 to 8'h01
        else if (op1 < 4'h6) pc <= pc + 2; //using op1 and op2 from 8'h02 to 8'h04
    end end
endmodule

module note_sine_gen(input clk, input [5:0] f_note, output reg [7:0] noteout);
reg [7:0] sine_table[0:99];     reg [7:0] table_index = 0;
reg [15:0] cnt = 0;             reg [15:0] freq [0:15];
reg [15:0] f = freq[f_note];    parameter slices = 100;

initial begin
    freq[0] = 0;
    freq[1] = 458; freq[2] = 408; freq[3] = 364; freq[4] = 344; freq[5] = 306; //C4
    freq[6] = 229; freq[7] = 204; freq[8] = 182; freq[9] = 172; freq[10] = 153; //C5
    // sine wave 100_sample lookup table(0~127)
    sine_table[ 0]=64 ;  sine_table[ 1]=67 ;  sine_table[ 2]=71 ;  sine_table[ 3]=75 ;  sine_table[ 4]=79 ;  
    sine_table[ 5]=83 ;  sine_table[ 6]=87 ;  sine_table[ 7]=90 ;  sine_table[ 8]=94 ;  sine_table[ 9]=97 ;  
    sine_table[10]=101;  sine_table[11]=104;  sine_table[12]=107;  sine_table[13]=109;  sine_table[14]=112;  
    sine_table[15]=114;  sine_table[16]=117;  sine_table[17]=119;  sine_table[18]=121;  sine_table[19]=122;  
    sine_table[20]=123;  sine_table[21]=125;  sine_table[22]=125;  sine_table[23]=126;  sine_table[24]=126;  
    sine_table[25]=127;  sine_table[26]=126;  sine_table[27]=126;  sine_table[28]=125;  sine_table[29]=125;  
    sine_table[30]=123;  sine_table[31]=122;  sine_table[32]=121;  sine_table[33]=119;  sine_table[34]=117;  
    sine_table[35]=114;  sine_table[36]=112;  sine_table[37]=109;  sine_table[38]=107;  sine_table[39]=104;  
    sine_table[40]=101;  sine_table[41]=97 ;  sine_table[42]=94 ;  sine_table[43]=90 ;  sine_table[44]=87 ;  
    sine_table[45]=83 ;  sine_table[46]=79 ;  sine_table[47]=75 ;  sine_table[48]=71 ;  sine_table[49]=67 ;  
    sine_table[50]=64 ;  sine_table[51]=60 ;  sine_table[52]=56 ;  sine_table[53]=52 ;  sine_table[54]=48 ;  
    sine_table[55]=44 ;  sine_table[56]=40 ;  sine_table[57]=37 ;  sine_table[58]=33 ;  sine_table[59]=30 ;  
    sine_table[60]=26 ;  sine_table[61]=23 ;  sine_table[62]=20 ;  sine_table[63]=18 ;  sine_table[64]=15 ;  
    sine_table[65]=13 ;  sine_table[66]=10 ;  sine_table[67]=8  ;  sine_table[68]=6  ;  sine_table[69]=5  ;  
    sine_table[70]=4  ;  sine_table[71]=2  ;  sine_table[72]=2  ;  sine_table[73]=1  ;  sine_table[74]=1  ;  
    sine_table[75]=0  ;  sine_table[76]=1  ;  sine_table[77]=1  ;  sine_table[78]=2  ;  sine_table[79]=2  ;  
    sine_table[80]=4  ;  sine_table[81]=5  ;  sine_table[82]=6  ;  sine_table[83]=8  ;  sine_table[84]=10 ;  
    sine_table[85]=13 ;  sine_table[86]=15 ;  sine_table[87]=18 ;  sine_table[88]=20 ;  sine_table[89]=23 ;  
    sine_table[90]=26 ;  sine_table[91]=30 ;  sine_table[92]=33 ;  sine_table[93]=37 ;  sine_table[94]=40 ;  
    sine_table[95]=44 ;  sine_table[96]=48 ;  sine_table[97]=52 ;  sine_table[98]=56 ;  sine_table[99]=60 ;  
end

always @(posedge clk)begin
    cnt = cnt + 1;
    if (cnt == f)begin
        cnt = 0;
        table_index = table_index + 1;
        if(table_index > slices-1) table_index = 0;
    end
    if (f==0) table_index = 75; // sine_table[75]=0
    noteout = sine_table[table_index]; end
endmodule

module sigma_delta_dac (input clk, input [MSBI:0] DACin, output reg DACout);
parameter MSBI = 7;
reg [MSBI+2:0] DeltaAdder;  reg [MSBI+2:0] SigmaAdder; 
reg [MSBI+2:0] SigmaLatch;  reg [MSBI+2:0] DeltaB;     

always @ (*) DeltaB = {SigmaLatch[MSBI+2], SigmaLatch[MSBI+2]} << (MSBI+1);
always @(*) DeltaAdder = DACin*2 + DeltaB;
always @(*) SigmaAdder = DeltaAdder + SigmaLatch;
always @(posedge clk)begin SigmaLatch <= SigmaAdder; DACout <= SigmaLatch[MSBI+2]; end
endmodule 