`timescale 1ns/1ps
module tb_pmod;
    localparam integer PERIOD=10;
    localparam integer FLASH=30;
    reg clk=0;
    reg [1:0] btn_n=2'b01, sw_n=2'b11;
    wire [7:0] led_n;
    cc07_pmod #(.CLK_HZ(1000), .SAMPLE_HZ(100), .PRESS_MS(30))
        dut(clk,btn_n,sw_n,led_n);
    always #5 clk=~clk;

    // Modelo independiente del filtro: ultimas K muestras habilitadas.
    reg [1:0] bm, bs, sm, ss;
    reg old_mode;
    reg [2:0] history3;
    reg [4:0] history5;
    reg level3, level5, play3, play5, pulse3, pulse5;
    reg reset_ref, tick_ref, previous_pulse, beat;
    reg [15:0] expected3, expected5;
    reg [7:0] expected_led;
    integer sample_count, flash_count, beat_count;
    integer checks=0, samples=0, presses3=0, presses5=0;
    reg valid=0;

    always @(posedge clk) begin
        reset_ref=bs[1] | (ss[1] != old_mode);
        tick_ref=(sample_count==PERIOD-1);
        previous_pulse=ss[1] ? pulse5 : pulse3;
        if (reset_ref === 1'b1) begin
            history3=0; history5=0;
            level3=0; level5=0; play3=0; play5=0;
            pulse3=0; pulse5=0;
            sample_count=0; flash_count=0; beat_count=0; beat=0;
            valid=1;
        end else if (valid) begin
            pulse3=0; pulse5=0;
            if (tick_ref && ss[0]) begin
                samples=samples+1;
                history3={history3[1:0],bs[0]};
                history5={history5[3:0],bs[0]};
                if (&history3 && !level3) begin
                    level3=1; play3=~play3; pulse3=1;
                    presses3=presses3+1;
                end else if (history3==0 && level3) level3=0;
                if (&history5 && !level5) begin
                    level5=1; play5=~play5; pulse5=1;
                    presses5=presses5+1;
                end else if (history5==0 && level5) level5=0;
            end
            if (tick_ref) sample_count=0;
            else sample_count=sample_count+1;
            if (previous_pulse) flash_count=FLASH;
            else if (flash_count!=0) flash_count=flash_count-1;
            if (beat_count==499) begin beat_count=0; beat=~beat; end
            else beat_count=beat_count+1;
        end
        old_mode=ss[1];
        bs=bm; bm=~btn_n;
        ss=sm; sm=~sw_n;
        expected3={13'b0,play3,pulse3,level3};
        expected5={13'b0,play5,pulse5,level5};
        expected_led=~{beat,bs[0],ss[1],~ss[1],ss[0],
                      (ss[1] ? play5 : play3),(flash_count!=0),
                      (ss[1] ? level5 : level3)};
        #1;
        if (valid) begin
            checks=checks+1;
            if (dut.y3 !== expected3 || dut.y5 !== expected5 ||
                led_n !== expected_led) begin
                $display("check=%0d y3=%h/%h y5=%h/%h led=%h/%h",
                         checks,dut.y3,expected3,dut.y5,expected5,led_n,expected_led);
                $fatal(1,"Error en adaptacion PMOD");
            end
        end
    end

    task clocks;
        input integer n;
        integer i;
        begin for(i=0;i<n;i=i+1) begin @(posedge clk); #2; end end
    endtask
    task drive;
        input button, reset_button, enabled, k5;
        begin
            @(negedge clk);
            btn_n={~reset_button,~button};
            sw_n={~k5,~enabled};
        end
    endtask
    task next_sample;
        begin
            @(negedge clk);
            while(!dut.enable_core) @(negedge clk);
            @(posedge clk); #2;
        end
    endtask
    task state_is;
        input level, play;
        begin
            if (dut.selected_y[0] !== level || dut.selected_y[2] !== play)
                $fatal(1,"Estado dirigido incorrecto: esperado nivel=%b play=%b y=%h K5=%b samples=%0d",
                       level,play,dut.selected_y,dut.mode_k5,samples);
        end
    endtask

    integer i;
    reg [31:0] random_state=32'h20230113;
    initial begin
        clocks(7);
        state_is(0,0);
        drive(0,0,1,0); clocks(4); next_sample;
        drive(1,0,1,0); clocks(4);
        next_sample; state_is(0,0);
        next_sample; state_is(0,0);
        next_sample; state_is(1,1);
        clocks(100); state_is(1,1);
        if (!led_n[1]) $fatal(1,"LED press no se apago");
        drive(0,0,1,0); clocks(40); state_is(0,1);
        drive(1,0,1,0); clocks(40); state_is(1,0);

        // Dos muestras, pausa con cambios de boton, tercera al reanudar.
        drive(0,1,0,0); clocks(6);
        drive(0,0,1,0); clocks(4); next_sample;
        drive(1,0,1,0); clocks(4);
        next_sample; next_sample; state_is(0,0);
        drive(1,0,0,0); clocks(20); state_is(0,0);
        drive(0,0,0,0); clocks(20); state_is(0,0);
        drive(1,0,0,0); clocks(20); state_is(0,0);
        drive(1,0,1,0); clocks(14); state_is(1,1);
        // Reset prioritario mientras enable esta apagado.
        drive(1,1,0,0); clocks(6); state_is(0,0);

        // Cambiar el switch de K reinicia el estado.
        drive(0,0,0,1); clocks(6); state_is(0,0);
        if (led_n[5] !== 0 || led_n[4] !== 1) $fatal(1,"Indicadores K incorrectos");
        drive(0,0,1,1); clocks(4); next_sample;
        drive(1,0,1,1); clocks(4);
        for(i=0;i<4;i=i+1) begin next_sample; state_is(0,0); end
        next_sample; state_is(1,1);
        drive(0,0,1,1); clocks(60); state_is(0,1);
        drive(1,0,1,1); clocks(60); state_is(1,0);
        drive(1,0,1,0); clocks(6); state_is(0,0);

        // Estimulos reproducibles para entradas asincronas y cambios de modo.
        for(i=0;i<2000;i=i+1) begin
            random_state=random_state ^ (random_state<<13);
            random_state=random_state ^ (random_state>>17);
            random_state=random_state ^ (random_state<<5);
            drive(random_state[0],random_state[7:4]==0,
                  random_state[1],random_state[2]);
            clocks(2);
        end
        drive(0,1,1,0); clocks(6);
        drive(0,0,1,0); clocks(1100);
        if (presses3<4 || presses5<2 || checks<4000 || samples<100)
            $fatal(1,"Cobertura insuficiente");
        $display("PASS PMOD checks=%0d enabled_samples=%0d presses_K3=%0d presses_K5=%0d",
                 checks,samples,presses3,presses5);
        $finish;
    end
    initial begin #200000; $fatal(1,"Timeout PMOD"); end
endmodule
