module top_module #(parameter integer K=3)(
    input wire clk, rst, en,
    input wire [7:0] cmd, data,
    output wire [15:0] y
);
    reg nivel;
    reg press, play;
    reg [3:0] contador; // K entre 2 y 8.
    always @(posedge clk) begin
        if (rst) begin
            nivel <= 1'b0;
            contador <= 0;
            press <= 1'b0;
            play <= 1'b0;
        end else begin
          press <= 1'b0;
          if (en) begin
            if (cmd[0] == nivel)
                contador <= 0;
            else if (contador == K-1) begin
                nivel <= cmd[0];
                contador <= 0;
                if (cmd[0]) begin
                    press <= 1'b1;
                    play <= ~play;
                end
            end else
                contador <= contador + 1'b1;
          end
        end
    end
    assign y = {13'b0, play, press, nivel};
endmodule
