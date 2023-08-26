/*
 *   Simple CPU Example -- OK-8 with pwm-sqaurewave melody player
 */
module ok8 (input clk12, output speaker);

reg [23:0] counter;
always @(posedge clk12) counter = counter + 1;

reg [14:0] half_period[0:5];
initial begin
    // 12000000/(note*2) 4th octave
    half_period[0] = 0;     half_period[1] = 22900; half_period[2] = 20408;
    half_period[3] = 18182; half_period[4] = 17192; half_period[5] = 15306; 
end

reg n_reset;
poweronreset por(.clk(clk12), .n_reset(n_reset));

wire [7:0] spk;
ok8cpu cpu(.clk(counter[18]), .n_reset(n_reset), .spk(spk));

reg [14:0] count = 0;
always @(posedge clk12) begin
  count <= count + 1;
  if(spk == 8'h00)begin speaker <= 0; count <= 0; end
  else begin if (count >= half_period[spk]) begin speaker <= ~speaker; count <= 0; end end
  end // Invert speaker output to generate duty cycle 50% square wave
endmodule

module poweronreset(input clk, output n_reset);
	reg [7:0] counter;
	always @(posedge clk) if (counter != 8'b11111111) counter = counter + 8'b1;
	assign n_reset = counter == 8'b11111111;
endmodule

module ok8cpu(input clk, n_reset, output reg [7:0] spk);
    reg flg;        reg [7:0] mem[0:8'h2f];
    reg [7:0] rega; reg [15:0] pc;
	wire [8:0] op1, op2;
	assign op1 = mem[pc]; assign op2 = mem[pc + 1];
	always @(posedge clk, negedge n_reset) begin
		if (!n_reset) begin
            mem[0] <= 8'h02; mem[1] <= 8'h0A; // rega <= (melody location = 10)
            mem[2] <= 8'h03; mem[3] <= 8'h17; // if rega == 23, then jump to $00
            mem[4] <= 8'h04; mem[5] <= 8'h00; // 
            mem[6] <= 8'h00; // spk <= mem[rega]
            mem[7] <= 8'h01; // inc rega, jump to $02
            mem[8] <= 8'h04; mem[9] <= 8'h02; //
            // melody
            mem[10] <= 8'h05; mem[11] <= 8'h00; mem[12] <= 8'h03; mem[13] <= 8'h00;
            mem[14] <= 8'h03; mem[15] <= 8'h00; mem[16] <= 8'h00; mem[17] <= 8'h04;
            mem[18] <= 8'h00; mem[19] <= 8'h02; mem[20] <= 8'h00; mem[21] <= 8'h02;
            mem[22] <= 8'h00;
			pc  <= 0; flg <= 0; spk <= 0; rega <= 0;
		end else begin
			case (op1)
            8'h00: begin spk <= mem[rega]; flg <= 1; end // current note to speaker
            8'h01: begin rega <= rega + 1; flg <= 1; end // next position of the melody
            8'h02: begin rega <= op2; flg <= 1; end // setting the beginning of the melody
            8'h03: flg <= (rega == op2); // compare:if rega equals to op2
            8'h04: begin pc <= flg ? op2 : pc + 2; flg <= 1; end // jump to op2
        endcase
        if (op1 < 4'h2) pc <= pc + 1; //only using op1 while 8'h00
        else if (op1 < 4'h4) pc <= pc + 2; //using op1 and op2 from 8'h01 to 8'h03
    end end
endmodule
