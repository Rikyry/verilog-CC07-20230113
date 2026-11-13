module cc07_pmod #(
    parameter integer CLK_HZ = 50000000,
    parameter integer SAMPLE_HZ = 200,
    parameter integer PRESS_MS = 100
)(
    input wire clk,
    input wire [1:0] btn_n,
    input wire [1:0] sw_n,
    output wire [7:0] led_n
);
    // BTN4+4: pulsadores y switches activos en cero.
    // Dos etapas para las entradas fisicas; el reloj sigue siendo clk.
    reg [1:0] btn_meta, btn_sync;
    reg [1:0] sw_meta, sw_sync;
    reg mode_previous;
    always @(posedge clk) begin
        btn_meta <= ~btn_n;
        btn_sync <= btn_meta;
        sw_meta <= ~sw_n;
        sw_sync <= sw_meta;
        mode_previous <= sw_sync[1];
    end

    wire mode_k5 = sw_sync[1];
    // Cambiar K reinicia ambas instancias para evitar mezclar estados.
    wire reset_core = btn_sync[1] | (mode_k5 != mode_previous);
    localparam integer SAMPLE_CYCLES =
        (CLK_HZ / SAMPLE_HZ > 0) ? CLK_HZ / SAMPLE_HZ : 1;
    localparam integer PRESS_CYCLES =
        ((CLK_HZ / 1000) * PRESS_MS > 0) ? (CLK_HZ / 1000) * PRESS_MS : 1;
    localparam integer HEART_CYCLES = (CLK_HZ / 2 > 0) ? CLK_HZ / 2 : 1;

    reg [31:0] sample_counter;
    wire sample_tick = (sample_counter == SAMPLE_CYCLES-1);
    wire enable_core = sample_tick & sw_sync[0];
    always @(posedge clk) begin
        if (reset_core || sample_tick)
            sample_counter <= 0;
        else
            sample_counter <= sample_counter + 1'b1;
    end

    wire [15:0] y3, y5;
    wire [15:0] selected_y = mode_k5 ? y5 : y3;
    top_module #(.K(3)) filtro3 (
        .clk(clk), .rst(reset_core), .en(enable_core),
        .cmd({7'b0,btn_sync[0]}), .data(8'b0), .y(y3)
    );
    top_module #(.K(5)) filtro5 (
        .clk(clk), .rst(reset_core), .en(enable_core),
        .cmd({7'b0,btn_sync[0]}), .data(8'b0), .y(y5)
    );

    // El pulso real sigue durando un ciclo. Solo su LED dura 100 ms.
    reg [31:0] press_counter;
    reg [31:0] heart_counter;
    reg heartbeat;
    always @(posedge clk) begin
        if (reset_core) begin
            press_counter <= 0;
            heart_counter <= 0;
            heartbeat <= 0;
        end else begin
            if (selected_y[1])
                press_counter <= PRESS_CYCLES;
            else if (press_counter != 0)
                press_counter <= press_counter - 1'b1;
            if (heart_counter == HEART_CYCLES-1) begin
                heart_counter <= 0;
                heartbeat <= ~heartbeat;
            end else
                heart_counter <= heart_counter + 1'b1;
        end
    end

    // LED D1..D8: nivel, press visible, play, enable, K3, K5, boton, reloj.
    wire [7:0] indicators = {
        heartbeat, btn_sync[0], mode_k5, ~mode_k5,
        sw_sync[0], selected_y[2], (press_counter != 0), selected_y[0]
    };
    assign led_n = ~indicators;
endmodule
