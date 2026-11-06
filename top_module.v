module top_module #(parameter integer K=3)(
    input wire clk, rst, en,
    input wire [7:0] cmd, data,
    output wire [15:0] y
);
    // Primera etapa: interfaz; falta implementar el filtro.
    assign y = 16'b0;
endmodule
