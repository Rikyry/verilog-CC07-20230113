# CC07: filtro de botón y reproducción

Matrícula: 20230113  
Correo: 20230113@itla.edu.do

Fuente: CC07_20230113_25_puntos.docx. Proyecto independiente del reto de la ALU.

## Funcionamiento

El circuito guarda el nivel filtrado, un contador, press y play. Sólo usa
cmd[0]. data y cmd[7:1] se ignoran. La salida es y[0]=nivel, y[1]=press,
y[2]=play y y[15:3]=0. K es entero y admite el intervalo 2 a 8.

El contador acumula muestras habilitadas distintas del nivel aceptado. En la
muestra K cambia el nivel y vuelve a cero. Una muestra habilitada igual al
nivel aceptado borra la cuenta. Al aceptar 0 a 1, press vale uno durante ese
ciclo y play cambia de estado. Mantener el botón alto no repite el evento.
Aceptar una liberación no cambia play y permite otra pulsación.

Prioridad en cada flanco positivo:

1. rst borra todo, aunque en=0 o el botón esté alto.
2. Sin reset, press se borra siempre.
3. Con en=1 se procesa la muestra; con en=0 se conservan nivel, contador y play.

Caso límite: con K=3 y dos muestras altas acumuladas, una pausa conserva la
cuenta aunque el botón cambie durante ella. La siguiente muestra habilitada
alta acepta la pulsación. Si esa muestra es baja, borra la cuenta. Si la pausa
empieza después de una aceptación, press se borra en su primer flanco.

El DUT usa Verilog 2001, un único reloj y asignaciones no bloqueantes para
estado. No contiene initial, retardos, force ni lectura de archivos. Las
entradas ya son síncronas según el enunciado.

## Ejecutar

Instalar Icarus Verilog 12 o posterior y poner iverilog y vvp en PATH.
Desde la raíz del repositorio:

```sh
iverilog -g2012 -s tb_student -o sim top_module.v tb_student.v
vvp sim
```

El DUT también puede compilarse por separado en modo Verilog 2001:

```sh
iverilog -g2001 -s top_module -o rtl_check top_module.v
```

No subir sim ni rtl_check al repositorio. El testbench usa características de
simulación permitidas por -g2012; el DUT conserva compatibilidad Verilog 2001.

## Pruebas propias y resultados

Se ejecutan K=3 y K=5 en paralelo. Cada paso aplica entradas en el flanco
negativo y compara los 16 bits de y un nanosegundo después del positivo.
La comparación estricta detecta X y Z. El modelo cuenta la longitud de la
racha, sin leer señales internas del DUT. Un fallo termina con código no cero.

| Grupo propio | Caso | Comparaciones K=3 | Comparaciones K=5 |
| --- | --- | ---: | ---: |
| G1 | Reset con botón alto y play activo; prioridad sobre enable | 9 | 13 |
| G2 | Pulsar, mantener, liberar y volver a pulsar | 19 | 27 |
| G3 | Rebotes de K-1 muestras y aceptación exacta en K | 22 | 36 |
| G4 | Pausa antes de K, conservación de cuenta y borrado de press | 17 | 25 |
| G5 | Reset durante pulsación y liberación; liberación en pausa | 22 | 34 |
| G6 | 900 ciclos pseudoaleatorios con reset, pausas y bits no usados | 900 | 900 |
| Total | Todas correctas | 989 | 1035 |

Semilla: 32'h20230113 XOR K, generador xorshift32 implementado en el testbench.
Son pruebas propias basadas en el contrato; no son los archivos privados del docente.

Verificación local: Icarus 14.0 (devel), Windows. El compilador instalado genera
el archivo de simulación, pero su proceso termina con -1073741819
(0xC0000005). Ocurrió también al compilar sólo el DUT con -g2001. vvp ejecutó
archivos recién generados y terminó con código 0 y el siguiente resultado:

```text
PASS K=3 total=989
PASS K=5 total=1035
PASS tb_student: K=3 y K=5
```

La simulación pasó 2024 comparaciones. Queda pendiente confirmar una compilación
con salida 0 en una instalación estable de Icarus 12 o posterior. Esta prueba
no sustituye una herramienta de síntesis. No se hizo prueba física ni se requiere FPGA.

## Avance real

| Commit | Avance |
| --- | --- |
| cad42abaf12d23116617fee468212e365b778562 | Interfaz, estructura y plan; salida provisional cero |
| 2001e90eea7216b62fb64b76d813f23e4089f94d | Filtro parcial funcional, contador, reset y pausa; sin press ni play |
| 4497b1d0179663ea4ad559d711d67763488f6641 | press y play; comprobaciones automáticas y simulación de ambos K |
| 92c5a273ebe3d9935d8136e32bdaca6bbe6b390f | Solución final documentada, resultados y limitación del compilador |
| HEAD: obtener con git rev-parse HEAD | Actualización de la entrega con el enlace del repositorio publicado |

El hash de un commit no puede incluirse dentro de ese mismo commit: cambiar el
README cambiaría el hash. El hash completo final se entrega aparte y se obtiene
con `git rev-parse HEAD`. Para ver las cuatro etapas: `git log --reverse --oneline`.
No se reescribió ni se hizo squash del historial.

## Entrega

Repositorio público: [Rikyry/verilog-CC07-20230113](https://github.com/Rikyry/verilog-CC07-20230113).
Se publicó la rama main con las cuatro etapas originales completas y una
actualización de documentación. Para descargarlo y consultar el hash a entregar:

```sh
git clone https://github.com/Rikyry/verilog-CC07-20230113.git
cd verilog-CC07-20230113
git rev-parse HEAD
```

Entregar el enlace del repositorio y el hash completo final. Los comandos de
simulación indicados arriba se ejecutan dentro de la carpeta descargada.
