# CC07 - Filtro de botón y reproducción

Nombre: Riky Ramos  
Matrícula: 20230113  
Correo: 20230113@itla.edu.do

## Cómo funciona

El circuito guarda el nivel del botón, un contador, press y play.
Sólo usa cmd[0]. Si el botón es distinto del nivel guardado, cuenta las
muestras con en=1. Al completar K muestras acepta el cambio y borra la cuenta.
Si en una muestra habilitada el botón vuelve al nivel guardado, la cuenta
se borra. K puede valer de 2 a 8.

Cuando acepta un cambio de 0 a 1, press se activa por un ciclo y play cambia
de estado. Mantener el botón presionado no genera más pulsos. Para otra
pulsación primero hay que aceptar la liberación con K muestras bajas.

y[0] es el nivel filtrado, y[1] es press y y[2] es play. Los otros bits de y
quedan en cero. data y cmd[7:1] no se usan.

El reset es síncrono y tiene prioridad sobre en: en el flanco positivo borra
todo el estado. Con en=0 se conserva el contador, el nivel y play, pero press
se borra en cada flanco aunque esté en pausa.

Por ejemplo, con K=3, si hay dos muestras altas y se pausa, la cuenta queda
en dos. La próxima muestra habilitada alta acepta la pulsación; si es baja,
borra la cuenta. Lo que cambie el botón durante la pausa no cuenta.

## Cómo probarlo

Hace falta Icarus Verilog 12 o posterior en PATH. Desde la carpeta del proyecto:

```sh
iverilog -g2012 -s tb_student -o sim top_module.v tb_student.v
vvp sim
```

El testbench revisa la salida 1 ns después de cada flanco positivo.
Prueba pulsaciones, mantener y soltar el botón, rebotes, reset, prioridad y
pausas, incluyendo la pausa justo antes de completar K. También ejecuta
900 ciclos pseudoaleatorios por cada K con la semilla 32'h20230113 XOR K.

| K | Comparaciones correctas |
| --- | ---: |
| 3 | 989 de 989 |
| 5 | 1035 de 1035 |

vvp terminó con código 0. En esta máquina Icarus 14 de desarrollo generó sim,
pero el compilador terminó con el error de Windows 0xC0000005. Falta confirmar
la compilación sin ese error en una instalación estable.

## Commits del desarrollo

| Hash | Avance |
| --- | --- |
| cad42ab | Interfaz y plan |
| 2001e90 | Filtro parcial con contador y pausa |
| 4497b1d | press, play y pruebas automáticas |
| 92c5a27 | Solución final documentada y resultados |

Después se actualizó el enlace del repositorio y se simplificó este README.
El historial completo se ve con `git log --oneline`.

Repositorio: https://github.com/Rikyry/verilog-CC07-20230113

Para obtener el hash completo del último commit que se entrega:

```sh
git rev-parse HEAD
```
