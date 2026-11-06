# CC07 - Filtro de botón

Matrícula: 20230113  
Correo: 20230113@itla.edu.do

Reto: filtro de botón y conmutación de reproducción, del archivo
CC07_20230113_25_puntos.docx.

## Cómo funciona

La idea es que un rebote corto del botón no cuente como una pulsación.
Para eso el circuito guarda el nivel del botón y lleva un contador.
Si cmd[0] es diferente del nivel guardado, va contando las muestras con en=1.
Cuando llega a K, acepta el nuevo nivel y pone el contador en cero.
Si antes de llegar a K el botón vuelve al nivel guardado, la cuenta se borra.
K puede valer de 2 a 8.

Al aceptar el cambio de 0 a 1 sale un pulso press y play cambia de estado.
Dejar el botón presionado no genera más pulsos. Hay que soltarlo durante K
muestras habilitadas para que se pueda aceptar otra pulsación.

Las salidas son y[0] para el nivel, y[1] para press y y[2] para play.
Los demás bits de y quedan en cero. Sólo se usa cmd[0]; data y los otros bits
de cmd se ignoran.

## Reset y pausa

El reset es síncrono y tiene prioridad sobre en. En el flanco positivo,
si rst=1, el nivel, contador, press y play quedan en cero.
Si en=0, se conserva la cuenta, el nivel y play. press sí se borra en cada
flanco, incluso estando en pausa.

Un caso límite: con K=3, si ya se contaron dos muestras altas y se pausa,
la cuenta sigue en dos. Al habilitar otra vez, una muestra alta completa la
pulsación. Si esa muestra es baja, se borra la cuenta y toca empezar de nuevo.
Los cambios del botón durante la pausa no cuentan.

El módulo usa Verilog 2001 y sólo clk como reloj. El estado se actualiza con
asignaciones no bloqueantes. En top_module no hay initial ni retardos.

## Cómo correr las pruebas

Hace falta Icarus Verilog 12 o más reciente, con iverilog y vvp en PATH.
En la carpeta del proyecto se ejecuta:

```sh
iverilog -g2012 -s tb_student -o sim top_module.v tb_student.v
vvp sim
```

El archivo sim que se genera no se sube al repositorio.

## Pruebas y resultado

El testbench prueba K=3 y K=5. Revisa los 16 bits de la salida 1 ns después
de cada flanco positivo y termina con error si algo no coincide, incluso X o Z.

Las pruebas incluyen pulsar, mantener, soltar y volver a pulsar; reset con el
botón alto y play activo; rebotes de K-1 muestras; aceptación en K; pausas antes
de completar la cuenta; borrado de press en pausa; y reset durante pulsación
y liberación, también con en=0.

Además hay 900 ciclos pseudoaleatorios por cada K, variando reset, enable,
cmd y data. La semilla es 32'h20230113 XOR K y se usa xorshift32, así que se
puede repetir la misma prueba.

| K | Comparaciones | Resultado |
| --- | ---: | --- |
| 3 | 989 | Todas correctas |
| 5 | 1035 | Todas correctas |

La salida obtenida fue:

```text
PASS K=3 total=989
PASS K=5 total=1035
PASS tb_student: K=3 y K=5
```

Hubo un problema con Icarus 14.0 de desarrollo instalado en Windows: genera
el archivo sim, pero el compilador termina con el error 0xC0000005.
También pasó al compilar sólo el módulo con -g2001. vvp sí ejecutó los archivos
recién generados y terminó con código 0. Pasaron las 2024 comparaciones;
falta comprobar que el compilador termine sin error en una instalación estable.
No se requiere tarjeta FPGA para este reto.

## Commits

| Hash | Cambio |
| --- | --- |
| cad42ab | Interfaz y plan de trabajo |
| 2001e90 | Filtro parcial con contador y pausa |
| 4497b1d | press, play y pruebas automáticas |
| 92c5a27 | Documentación de la solución y los resultados |
| ccc11c4 | Enlace del repositorio publicado |
| HEAD | README simplificado |

Las cuatro etapas originales siguen en el historial. Se pueden ver con
`git log --reverse --oneline`.

## Entrega

Repositorio: https://github.com/Rikyry/verilog-CC07-20230113

Los archivos son top_module.v, tb_student.v y README.md.
Para obtener el hash completo del último commit que se entrega:

```sh
git rev-parse HEAD
```
