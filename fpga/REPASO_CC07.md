# Repaso CC07: filtro de botón

Riky Ramos — Matrícula 20230113

## La idea del proyecto

El botón puede hacer varios cambios rápidos cuando se presiona o se suelta.
Eso se llama rebote. Si cada cambio se toma como una pulsación, una sola
presión podría cambiar `play` varias veces.

El filtro espera K muestras válidas del valor contrario al nivel que ya
tenía guardado. Cuando llega a K, acepta ese nuevo nivel. Al aceptar una
pulsación de 0 a 1, genera `press` y cambia `play` al estado contrario.
Al aceptar la liberación de 1 a 0, cambia el nivel, pero no cambia `play`.

Hay dos partes:

- `top_module.v`: resuelve el reto con la interfaz pedida. No depende de la
  Tang Primer ni de los LED. Es Verilog 2001 sintetizable, sin `initial` ni
  retardos `#` en el circuito.
- `fpga/src/cc07_pmod.v`: conecta ese mismo circuito a la Tang Primer 25K.
  Sincroniza las entradas físicas, toma muestras cada 5 ms, selecciona K=3
  o K=5 y prepara los indicadores LED.

## Las entradas y salidas del reto

La interfaz es:

```verilog
module top_module #(parameter integer K=3)(
    input wire clk, rst, en,
    input wire [7:0] cmd, data,
    output wire [15:0] y
);
```

| Señal | Para qué sirve |
| --- | --- |
| `clk` | El estado se actualiza en su flanco positivo. |
| `rst` | Reset activo en 1, síncrono y con prioridad. |
| `en` | En 1 permite tomar una muestra; en 0 pausa el filtro. |
| `cmd[0]` | Valor del botón que se va a filtrar. |
| `cmd[7:1]`, `data` | No se usan en este reto. |
| `y[0]` | `nivel`: valor del botón ya aceptado. |
| `y[1]` | `press`: pulso de una pulsación aceptada. |
| `y[2]` | `play`: estado que alterna con cada pulsación aceptada. |
| `y[15:3]` | Siempre quedan en cero. |

K es un parámetro de construcción del módulo, no una entrada que se cambia
durante su ejecución. El código del reto se usa con K entre 2 y 8. En la
placa hay dos instancias, una de K=3 y otra de K=5; un switch selecciona cuál
se muestra. Cambiar ese switch reinicia el estado de ambas.

## Qué ocurre en cada flanco positivo

1. Si `rst=1`, se borran `nivel`, `contador`, `press` y `play`, aunque `en=0`.
2. Si no hay reset, `press` vuelve a cero por defecto.
3. Si `en=0`, `contador`, `nivel` y `play` conservan su valor.
4. Si `en=1` y el botón coincide con `nivel`, `contador` vuelve a cero.
5. Si `en=1` y el botón es distinto de `nivel`, se cuenta esa muestra.
6. Al completar K muestras, se acepta el nuevo nivel y se borra la cuenta.
   Si el nuevo nivel es 1, `press=1` y `play` se invierte.

Las muestras son consecutivas entre las que tienen `en=1`. Los cambios del
botón durante la pausa no se cuentan. Tampoco se puede detectar un cambio
que ocurra y desaparezca entre dos muestras: el circuito trabaja con los
valores que alcanza a muestrear.

### Por qué se compara con K-1

El contador guarda cuántas muestras opuestas se habían visto antes del
flanco actual. La comparación usa ese valor anterior.

Con K=3, las dos primeras muestras dejan el contador en 1 y 2. En la
tercera muestra ya estaba en 2, que es K-1, así que se acepta el cambio y
se pone en cero. No hace falta guardar un 3.

Con K=5, se guarda 1, 2, 3 y 4. La quinta muestra encuentra el 4 y acepta.
Durante una cuenta válida, el contador recorre de 0 a K-1. El registro de
4 bits tiene espacio suficiente para los valores de K usados aquí.

Las asignaciones `<=` actualizan los registros después de evaluar el
flanco. Por eso `contador == K-1` compara la cuenta anterior, y
`play <= ~play` invierte el valor anterior de `play`.

### Ejemplo de K=3 con pausa

Cada fila muestra un flanco positivo. Los valores de la derecha son los
que quedan después del flanco. Las filas con `en=0` no cuentan muestras.

| Paso | `rst` | `en` | Botón | Contador | Nivel | `press` | `play` | Qué pasó |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Inicio | 1 | 0 | 0 | 0 | 0 | 0 | 0 | Reset, incluso con pausa. |
| 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | Primera muestra alta. |
| 2 | 0 | 1 | 1 | 2 | 0 | 0 | 0 | Segunda muestra alta. |
| 3 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | Pausa: el cero no borra la cuenta. |
| 4 | 0 | 0 | 1 | 2 | 0 | 0 | 0 | Sigue en pausa. |
| 5 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | Tercera muestra válida: acepta. |
| 6 | 0 | 0 | 1 | 0 | 1 | 0 | 1 | Pausa: `press` se borra igualmente. |
| 7 | 0 | 1 | 1 | 0 | 1 | 0 | 1 | Mantenerlo alto no repite el pulso. |
| 8 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | Primera muestra para soltar. |
| 9 | 0 | 1 | 0 | 2 | 1 | 0 | 1 | Segunda muestra para soltar. |
| 10 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | Acepta soltar; `play` sigue igual. |
| 11 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | Empieza otra pulsación. |
| 12 | 0 | 1 | 1 | 2 | 0 | 0 | 1 | Segunda muestra. |
| 13 | 0 | 1 | 1 | 0 | 1 | 1 | 0 | Nueva pulsación: ahora apaga `play`. |
| 14 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | Reset tiene prioridad sobre pausa. |

Si en el paso 5 el botón fuera 0, coincidiría con `nivel`: se borraría la
cuenta y no habría pulsación. Para aceptarla habría que empezar a contar
las muestras altas otra vez.

Un rebote muestreado con K=3 podría verse como `1, 1, 0, 1, 1, 1`, empezando
desde nivel 0. El cero rompe la primera cuenta. Se acepta el cambio en el
último 1, después de tres muestras altas seguidas y habilitadas.

Con K=5 se hace lo mismo, pero cuatro muestras opuestas todavía no bastan.
La quinta acepta. Para liberar el botón también hacen falta cinco bajas.

## Tres detalles que hay que saber explicar

**`nivel`, `press` y `play` son cosas distintas.** `nivel` dice si el botón
ya fue aceptado como presionado. `press` avisa una sola vez al aceptarlo.
`play` guarda el resultado de alternar: una pulsación lo enciende, otra lo
apaga. Por eso `play` puede quedarse encendido después de soltar el botón.

**Mantener presionado no equivale a repetir pulsaciones.** Después de
aceptar nivel 1, más muestras altas coinciden con ese nivel. Para otra
pulsación primero debe aceptarse la liberación con K muestras bajas y
después una nueva subida con K muestras altas.

**Pausar no detiene el reloj.** El reloj sigue llegando. El `if (en)` evita
actualizar la cuenta, el nivel y `play`. `press` se borra en el siguiente
flanco aunque siga la pausa. Reset también sigue funcionando porque se
revisa antes de `en`.

## Cómo se conecta a la placa

La placa es una Tang Primer 25K con Dock. El módulo PMOD-BTN4+4 va en J6 y
PMOD-LEDx8 en J4; J5 queda libre. Con USB-C a la derecha, USB-A grande a la
izquierda y los tres conectores PMOD hacia abajo, botones quedan a la
izquierda y LED a la derecha. Para mover módulos se desconecta primero
el USB y se revisa que coincidan 3V3 y GND.

### Botones y switches que ya se probaron

Para esta numeración, mirar la cara de componentes del módulo con los
**cuatro botones blancos arriba, las cuatro palancas debajo y el conector
abajo**. Contar de izquierda a derecha:

```text
Botones:  [1: prueba] [2: reset] [3: sin uso] [4: sin uso]
Switches: [1: enable] [2: K]     [3: sin uso] [4: sin uso]
                        conector abajo
```

| Control | Función | Entrada física |
| --- | --- | --- |
| Botón 1, extremo izquierdo en esa orientación | Pulsación de prueba | `btn_n[0]`, F5, J6.11 |
| Botón 2, al lado del primero | Reset | `btn_n[1]`, G7, J6.9 |
| Switch 1, alineado con botón 1 | ON habilita, OFF pausa | `sw_n[0]`, G5, J6.12 |
| Switch 2, alineado con botón 2 | OFF selecciona K=3; ON, K=5 | `sw_n[1]`, G8, J6.10 |

Cada switch es una sola palanca, aunque las cuatro estén en dos grupos.
Los controles 3 y 4 no se usan. No hace falta poner los cuatro en ON.

### Por qué las entradas terminan en `_n`

Los contactos son activos en cero. Las resistencias de pull-up mantienen
un 1 cuando el contacto está abierto. Al presionar el botón o poner un
switch en ON, el contacto va a GND y se lee un 0 físico. La adaptación
invierte esas entradas con `~` para trabajar internamente con 1 como
presionado, habilitado o K5 seleccionado.

Los LED también son activos en cero. Por eso al final se usa
`led_n = ~indicators`: un indicador lógico 1 produce un 0 en el pin y
enciende el LED.

### Dos registros para sincronizar

Las entradas externas pueden cambiar en cualquier momento, sin seguir el
reloj de la FPGA. Primero pasan por `btn_meta`/`sw_meta` y después por
`btn_sync`/`sw_sync`, dos etapas de registros con el mismo reloj.

Esto reduce la probabilidad de que una entrada que cambia cerca del flanco
cause problemas de metastabilidad en la lógica siguiente. No elimina el
rebote; sincronización y filtrado resuelven problemas diferentes. También
agrega un pequeño retraso de unos ciclos de reloj.

### Un reloj de 50 MHz y una muestra cada 5 ms

El reloj sigue siendo de 50 MHz, conectado al pin E2. Su periodo es:

```text
1 / 50 000 000 = 20 ns
50 000 000 / 200 muestras por segundo = 250 000 ciclos por muestra
1 / 200 = 5 ms entre muestras
```

`sample_counter` cuenta esos ciclos. Al llegar a 249999 produce
`sample_tick`. El filtro recibe `en = sample_tick & enable_del_switch`.
Se usa una habilitación dentro del mismo reloj; no se crea otro reloj para
el filtro.

Con K=3 se suele hablar de unos 15 ms y con K=5 de unos 25 ms. Son valores
aproximados: desde un cambio estable del botón, el tiempo hasta aceptarlo
depende de cuándo cae la primera muestra. Sin rebotes ni pausa, está cerca
de 10 a 15 ms para K=3 y de 20 a 25 ms para K=5, más el pequeño retraso de
sincronización. Si hay rebotes muestreados, la espera puede ser mayor.
**Esos tiempos no se midieron físicamente con instrumentos.**

Al pausar se conserva el contador de estabilidad dentro de `top_module`.
El contador que genera `sample_tick` sigue avanzando. Al reanudar, la
próxima muestra válida completa o continúa la cuenta que había quedado;
no se garantiza esperar otros 5 ms completos desde que se mueve el switch.

### El pulso y el LED no duran lo mismo

`press` del reto dura un solo ciclo de `clk`, o sea 20 ns con el reloj de
50 MHz. No dura 5 ms: entre muestras el reloj sigue funcionando y en el
siguiente flanco se borra el pulso.

Un LED no permite ver un pulso de 20 ns. La adaptación detecta `press` y
mantiene su indicador aproximadamente 100 ms, contando 5000000 ciclos.
Esto sólo alarga la luz de D2; no modifica `press` ni cambia la lógica de
`top_module`. El indicador puede seguir encendido un rato al pausar, hasta
terminar esos 100 ms. Reset lo apaga.

### Mapa de los LED

D1 a D8 son los nombres del esquema del módulo. La tabla usa esa numeración,
sin depender de cómo se gire el módulo al mirarlo.

| LED | Indicador | Pin de la FPGA |
| --- | --- | --- |
| D1 | Nivel filtrado | G11 |
| D2 | `press` visible durante unos 100 ms | G10 |
| D3 | `play`, conserva el estado al soltar | D11 |
| D4 | Enable del switch activo | D10 |
| D5 | K=3 seleccionado | C10 |
| D6 | K=5 seleccionado | C11 |
| D7 | Botón sincronizado antes del filtro | B10 |
| D8 | Parpadeo de funcionamiento | B11 |

D8 cambia cada medio segundo: encendido más apagado completan un segundo.
Sigue parpadeando durante la pausa. Al mantener reset, el contador de ese
indicador también se reinicia.

D7 puede responder antes que D1 porque todavía no ha pasado por el filtro.
D4 sólo indica el estado de enable; no es el pulso de muestreo de 5 ms.

## Qué se comprobó

### En simulación

`tb_student.v` compara el circuito con un modelo de referencia. Prueba reset,
prioridad, pulsaciones, mantener presionado, liberación, rebotes y pausas,
incluyendo la pausa justo antes de completar K. También prueba 900 ciclos
pseudoaleatorios por cada K, con semilla `32'h20230113 ^ K` para poder
repetir los mismos estímulos.

Los resultados registrados son 989 comparaciones correctas para K=3 y
1035 para K=5. La adaptación también tiene `fpga/sim/tb_pmod.v`, con 5640
comprobaciones por ciclo: sincronización, muestreo, ambos K, reset, pausa,
indicador de `press`, polaridad de LED y parpadeo. Se usaron parámetros de
tiempo reducidos para simular esos contadores más rápido.

Los resultados están en `fpga/RESULTADOS.txt`. Ahí también figuran la síntesis
y el place & route completados, con cero violaciones informadas de setup y
hold para la restricción de 50 MHz.

### En la placa, el 13 de noviembre de 2026

La carga SRAM terminó con `Finished` en Gowin Programmer. Con los dos módulos
conectados se confirmaron visualmente estas pruebas:

- K=5: una pulsación enciende `play`, la siguiente lo apaga y el estado se
  conserva al soltar.
- El botón 2 reinicia el estado.
- Con `play` encendido, la pausa evita que nuevas pulsaciones lo cambien.
- Al reanudar, otra pulsación vuelve a cambiar `play`.
- K=3: la alternancia de `play` también funciona.
- En pausa, reset apaga `play` igualmente.

La prueba visual confirma ese comportamiento de uso. Los K ciclos exactos,
el ancho de un ciclo de `press`, los rebotes y las secuencias aleatorias se
comprobaron en simulación. La vista no mide 20 ns ni comprueba por sí sola
la cuenta exacta que hay dentro de la FPGA.

## Para abrirlo y mostrarlo otra vez

Los archivos principales son:

| Archivo | Contenido |
| --- | --- |
| `top_module.v` | Circuito del reto. |
| `tb_student.v` | Pruebas del circuito del reto. |
| `fpga/cc07_pmod.gprj` | Proyecto para abrir en GOWIN IDE. |
| `fpga/src/cc07_pmod.v` | Adaptación a botones, switches y LED. |
| `fpga/constraints/cc07_pmod.cst` | Asignación de señales a pines. |
| `fpga/constraints/cc07_pmod.sdc` | Restricción del reloj de 20 ns y otras restricciones. |
| `fpga/build.tcl` | Generación del proyecto y del archivo para programar. |
| `fpga/bitstream/cc07_pmod.fs` | Archivo que se carga en la FPGA después de generarlo. |
| `fpga/LEEME.txt` | Montaje, controles y comandos. |
| `fpga/RESULTADOS.txt` | Resultados registrados de verificación y de placa. |

Se debe conservar la estructura completa de carpetas. El proyecto usa
archivos de más de una carpeta; copiar sólo el `.gprj` no lleva el circuito.
En GOWIN el módulo superior para la placa es `cc07_pmod` y el dispositivo
es `GW5A-LV25MG121NC1/I0`, versión A.

Para mostrarlo:

1. Conectar los módulos en J6 y J4 con la alimentación desconectada y luego
   conectar el USB-C de datos.
2. Abrir el proyecto de GOWIN. Para programar usar el `.fs` generado y la
   operación `SRAM Program` en Gowin Programmer.
3. Esperar a que termine con `Finished`.
4. Elegir K con el switch 2 y dejar el switch 1 en ON.
5. Presionar y soltar el botón 2 para resetear. El código no tiene un reset
   automático de encendido, así que este paso es necesario después de cargar.
6. Probar el botón 1: presionar, mantener, soltar y volver a presionar.
7. Probar pausa y reanudación. Probar también reset durante la pausa.
8. Cambiar K y repetir. El cambio de modo borra el estado anterior.

La carga en SRAM es volátil: al quitar la alimentación se pierde y hay que
cargarla otra vez. Que se haya cargado en SRAM no significa que haya quedado
grabada en la memoria flash para arrancar sola.

## Explicación corta para decirla en clase

“Este circuito filtra un botón contando muestras. Si el botón es distinto
del nivel guardado, aumenta la cuenta; cuando completa K muestras acepta
el cambio. Si vuelve al nivel guardado antes de llegar, borra la cuenta.
Una subida aceptada genera un pulso llamado press y alterna play. Soltar
el botón sólo cambia el nivel.

El reset se aplica en el flanco positivo y tiene prioridad, incluso si el
circuito está en pausa. Con enable apagado guarda la cuenta, el nivel y
play, pero borra press.

Para usarlo en esta placa mantuve el reloj de 50 MHz y habilité una muestra
cada 5 ms. Las entradas pasan por dos registros de sincronización. El
switch de K selecciona una instancia de K=3 o una de K=5. El pulso real
de press dura 20 ns, y su LED se mantiene unos 100 ms para verlo. Probé
la alternancia en ambos modos, la pausa, la reanudación y el reset en pausa.”

## Diez preguntas para repasar

Hacer una pregunta cada vez y esperar a que Riky explique su razonamiento.
Antes de dar la respuesta, pedirle que prediga un ejemplo o una fila de la
tabla. Si se equivoca, señalar qué señal debe revisar y dejar que lo intente
otra vez. Después comparar con la respuesta y pasar a la siguiente.

1. **¿Qué diferencia hay entre `nivel`, `press` y `play`?**  
   Respuesta: `nivel` guarda el valor aceptado del botón; `press` avisa una
   subida aceptada durante un ciclo; `play` alterna y guarda su estado.

2. **Con K=3, ¿por qué se compara el contador con 2?**  
   Respuesta: al llegar la tercera muestra ya había dos guardadas. Se evalúa
   el contador anterior; esa muestra completa K y la cuenta vuelve a cero.

3. **Desde nivel 0, ¿qué hace K=3 con `1, 1, 0, 1, 1, 1`, todo habilitado?**  
   Respuesta: cuenta 1 y 2; el cero borra la cuenta. Los tres unos finales
   forman la racha válida. Sólo en el último acepta la subida y cambia `play`.

4. **Hay dos muestras altas con K=3 y se pausa. Durante la pausa el botón
   baja y vuelve a subir. ¿Qué pasa al reanudar con el botón alto?**  
   Respuesta: conserva la cuenta 2 durante la pausa. La siguiente muestra
   habilitada alta completa la pulsación. Si esa muestra fuera baja, borraría
   la cuenta. Lo que sólo pasó durante la pausa no se contó.

5. **¿Qué pasa con `rst=1` y `en=0` en el mismo flanco? ¿Y si reset cambia
   entre flancos?**  
   Respuesta: en el flanco se borra todo el estado porque reset tiene
   prioridad. Al ser síncrono, cambiar `rst` entre flancos no borra de
   inmediato los registros del módulo.

6. **Si se mantiene el botón alto mucho tiempo, ¿por qué `play` no sigue
   alternando? ¿Qué hace falta para otra pulsación?**  
   Respuesta: ya coincide con nivel 1 y no hay otra subida aceptada. Hay que
   aceptar K bajas para soltar y después K altas para la nueva pulsación.

7. **¿Para qué sirven las dos etapas de sincronización? ¿Quitan los rebotes?**  
   Respuesta: reducen el riesgo de propagar metastabilidad desde una entrada
   asíncrona. No quitan los rebotes; eso lo hace el filtro de muestras.

8. **¿Se hizo un reloj de 200 Hz? ¿Cuándo se toma una muestra?**  
   Respuesta: se conserva el reloj de 50 MHz. Cada 250000 ciclos se genera
   una habilitación; sólo se toma la muestra si además enable está activo.

9. **¿Por qué se ve D2 si `press` dura sólo 20 ns? ¿K=3 tarda siempre 15 ms?**  
   Respuesta: un contador aparte alarga el indicador a unos 100 ms. El
   circuito original conserva su pulso de un ciclo. Los 15 ms son una
   referencia aproximada; la fase del muestreo, los rebotes y la pausa
   afectan el tiempo desde que se toca el botón.

10. **Si mañana se conecta la placa y no funciona el circuito, ¿qué revisar
    primero? ¿Qué demostraron las pruebas físicas?**  
    Respuesta: verificar módulos en J6/J4, alimentación, cargar otra vez el
    `.fs` por SRAM, esperar `Finished`, habilitar y pulsar reset. La SRAM no
    conserva el programa sin alimentación. Las pruebas visuales confirmaron
    alternancia en K3/K5, pausa, reanudación y reset en pausa; los ciclos
    exactos y el pulso se verificaron en simulación.
