`timescale 1ns/1ps
module cc07_check #(parameter integer K=3)(output reg done);
    reg clk=0;
    reg rst, en;
    reg [7:0] cmd, data;
    wire [15:0] y;
    integer run_length, cycles, group_id, i, j;
    integer checks [1:6];
    reg level_ref, play_ref, press_ref;
    reg [15:0] expected;
    reg [31:0] random_state;
    top_module #(.K(K)) dut(clk,rst,en,cmd,data,y);
    always #5 clk=~clk;

    // Modelo: longitud de la racha de muestras habilitadas opuestas.
    task step;
        input r, e;
        input [7:0] c, d;
        begin
            @(negedge clk);
            rst=r; en=e; cmd=c; data=d;
            @(posedge clk);
            press_ref=0;
            if (r) begin
                level_ref=0; run_length=0; play_ref=0;
            end else if (e) begin
                if (c[0] == level_ref) run_length=0;
                else begin
                    run_length=run_length+1;
                    if (run_length == K) begin
                        level_ref=c[0]; run_length=0;
                        if (level_ref) begin
                            press_ref=1; play_ref=~play_ref;
                        end
                    end
                end
            end
            expected={13'b0,play_ref,press_ref,level_ref};
            #1;
            cycles=cycles+1;
            checks[group_id]=checks[group_id]+1;
            if (y !== expected) begin
                $display("FAIL K=%0d G%0d ciclo=%0d rst=%b en=%b cmd=%h data=%h y=%h esperado=%h",
                    K,group_id,cycles,r,e,c,d,y,expected);
                $fatal(1,"Comparacion incorrecta");
            end
        end
    endtask

    task hold_button;
        input b;
        input integer n;
        integer t;
        begin
            for (t=0;t<n;t=t+1) step(0,1,{7'b0,b},8'h96);
        end
    endtask

    initial begin
        done=0; rst=1; en=0; cmd=0; data=0;
        cycles=0; run_length=0; level_ref=0; press_ref=0; play_ref=0;
        for (j=1;j<=6;j=j+1) checks[j]=0;
        group_id=1;
        step(1,0,8'hff,8'hff);
        hold_button(1,K);
        step(1,1,8'hff,8'hff); // reset con play activo y boton alto.
        hold_button(1,K);
        step(1,0,8'hff,0); // reset prioritario en pausa.

        group_id=2;
        hold_button(1,K); hold_button(1,K+3);
        hold_button(0,K); hold_button(0,2);
        hold_button(1,K); hold_button(1,2);

        group_id=3;
        step(1,1,0,0);
        for (i=0;i<3;i=i+1) begin
            hold_button(1,K-1); hold_button(0,1);
        end
        hold_button(1,K);
        hold_button(0,K-1); hold_button(1,1);
        hold_button(0,K); hold_button(1,K);

        group_id=4;
        step(1,1,0,0); hold_button(1,K-1);
        step(0,0,1,0); step(0,0,0,8'hff);
        step(0,1,1,0); // acepta tras pausa sin perder contador.
        step(0,0,1,0); // borra press inmediatamente.
        hold_button(0,K);
        hold_button(1,K-1); step(0,0,1,0);
        hold_button(0,1); hold_button(1,K); // rebote borra racha.

        group_id=5;
        step(1,1,0,0); hold_button(1,K-1);
        step(1,1,1,0); hold_button(1,K);
        hold_button(0,K-1); step(1,0,0,0);
        hold_button(1,K); step(0,0,0,0);
        step(0,0,0,0); hold_button(1,1);
        hold_button(0,K); hold_button(1,K);

        group_id=6;
        random_state=32'h20230113 ^ K;
        for (i=0;i<900;i=i+1) begin
            // Xorshift32: misma secuencia en cada ejecucion.
            random_state=random_state ^ (random_state << 13);
            random_state=random_state ^ (random_state >> 17);
            random_state=random_state ^ (random_state << 5);
            step(random_state[7:4]==0,random_state[2:1]!=0,
                 random_state[15:8],random_state[31:24]);
        end
        for (j=1;j<=6;j=j+1)
            $display("PASS K=%0d G%0d comparaciones=%0d",K,j,checks[j]);
        $display("PASS K=%0d total=%0d",K,cycles);
        done=1;
    end
endmodule

module tb_student;
    wire done3, done5;
    cc07_check #(.K(3)) c3(done3);
    cc07_check #(.K(5)) c5(done5);
    initial begin
        wait(done3 && done5);
        $display("PASS tb_student: K=3 y K=5");
        $finish;
    end
    initial begin
        #100000;
        $fatal(1,"Tiempo de simulacion agotado");
    end
endmodule
