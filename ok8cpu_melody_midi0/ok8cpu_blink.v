/*
 *   Simple CPU Example -- OK-8 with Blink codes for OK-iCE40Pro FPGA kit
 */
module ok8 (input clk12, output led_b, led_r);

  reg [23:0] counter;
  always @(posedge clk12) counter = counter + 1;

  reg n_reset;
  poweronreset por(.clk(clk12), .n_reset(n_reset));

  wire [7:0] lednum;
  ok8cpu cpu(.clk(counter[20]), .n_reset(n_reset), .lednum(lednum));
  assign led_b = lednum[0];
  assign led_r = lednum[1];
endmodule

module poweronreset(input clk, output n_reset);
	reg [7:0] counter;
	always @(posedge clk) if (counter != 8'b11111111) counter = counter + 8'b1;
	assign n_reset = (counter == 8'b11111111);
endmodule

module ok8cpu(input clk, n_reset, output reg [7:0] lednum);
	reg [7:0] mem[0:8'h0f];
	reg [7:0] rega;
	reg [15:0] pc;
	wire [8:0] op1, op2;
	assign op1 = mem[pc];
	assign op2 = mem[pc + 1];
	always @(posedge clk, negedge n_reset) begin
		if (!n_reset) begin
			mem[0] <= 8'h01; mem[1] <= 8'h01; // rega <= 2'b01
            mem[2] <= 8'h00; // lednum <= rega
			mem[3] <= 8'h01; mem[4] <= 8'h02; // rega <= 2'b10
            mem[5] <= 8'h00; // lednum <= rega
			mem[6] <= 8'h02; mem[7] <= 8'h00; // jump to $00
			pc <= 0; lednum <= 0;
		end else begin
			case (op1)
				8'h00: lednum <= rega;
                8'h01: rega   <= op2; 
				8'h02: pc     <= op2;
			endcase
			if (op1 < 4'h1) pc <= pc + 1; //only using op1 while 8'h00
			else if (op1 < 4'h2) pc <= pc + 2; //using op1 and op2 while 8'h01
		end end
endmodule
