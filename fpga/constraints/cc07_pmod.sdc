create_clock -name clk_50m -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]
// Las entradas externas solo van a la primera etapa del sincronizador.
set_false_path -from [get_ports {btn_n[*] sw_n[*]}]
// Indicadores visuales sin reloj externo; presupuesto de salida de 10 ns.
set_max_delay 10.000 -to [get_ports {led_n[*]}]
set_min_delay 0.000 -to [get_ports {led_n[*]}]
