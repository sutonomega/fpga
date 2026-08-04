module a_register (
  input  logic CLK,
  input  logic RST,
  input  logic [3:0] OPCODE,
  input  logic [3:0] DATA_IN,
  output logic [3:0] DATA_OUT
);

  always_ff @(posedge CLK) begin
    if (RST) begin
      DATA_OUT <= 4'h0; 
    end else begin
      case (OPCODE)
        4'h1:DATA_OUT <= DATA_IN;
        4'h2:DATA_OUT <= DATA_IN + DATA_OUT;
        4'h3:DATA_OUT <= DATA_IN - DATA_OUT;
        default:DATA_OUT <= DATA_OUT;
      endcase
    end
  end

endmodule
