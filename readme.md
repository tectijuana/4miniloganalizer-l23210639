# ======================================================
# ARCHIVO 1: analyzer.s
# ======================================================
cat << 'EOF' > analyzer.s
.data
    msg_alert:  .ascii "\n[CRITICAL] 3 Consecutive Errors Detected!\n"
    len_alert:  .quad 43
    buffer:     .byte 0

.text
.global _start

_start:
    mov x10, #0          // Inicializar contador de errores consecutivos

read_char:
    // Leer un byte de la entrada estándar (stdin)
    mov x0, #0           // fd 0: stdin
    ldr x1, =buffer
    mov x2, #1           // leer 1 byte
    mov x8, #63          // syscall: read
    svc #0

    // Si read retorna 0 o menos, es el fin del archivo (EOF)
    cmp x0, #0
    ble exit_normal

    ldrb w2, [x1]        // Cargar el byte leído

    // Filtrar caracteres no numéricos (espacios, tabs, saltos de línea)
    cmp w2, #'0'
    blo read_char        // Si es menor a '0', ignorar
    cmp w2, #'9'
    bhi read_char        // Si es mayor a '9', ignorar

    // Lógica de detección de errores (Códigos 4xx y 5xx)
    cmp w2, #'4'
    b.eq increment_error
    cmp w2, #'5'
    b.eq increment_error

    // SI NO ES ERROR: Reiniciar contador (Rompe la racha consecutiva)
    mov x10, #0
    b read_char

increment_error:
    add x10, x10, #1     // Sumar 1 al contador de consecutivos
    cmp x10, #3          // ¿Llegamos al límite?
    b.ge trigger_alert
    b read_char

trigger_alert:
    // Imprimir mensaje de alerta
    mov x0, #1           // fd 1: stdout
    ldr x1, =msg_alert
    ldr x2, =len_alert
    ldr x2, [x2]
    mov x8, #64          // syscall: write
    svc #0
    
    // Salir con código 1 indicando hallazgo
    mov x0, #1
    mov x8, #93
    svc #0

exit_normal:
    mov x0, #0           // Salida limpia (0 errores consecutivos detectados)
    mov x8, #93
    svc #0
EOF

# ======================================================
# ARCHIVO 2: Makefile
# ======================================================
cat << 'EOF' > Makefile
# Herramientas de compilación para ARM64
AS = as
LD = ld

all: analyzer

analyzer: analyzer.o
	$(LD) -o analyzer analyzer.o

analyzer.o: analyzer.s
	$(AS) -o analyzer.o analyzer.s

clean:
	rm -f analyzer analyzer.o
EOF

# ======================================================
# ARCHIVO 3: run.sh (Script de ejecución y prueba)
# ======================================================
cat << 'EOF' > run.sh
#!/bin/bash
# Compilar el proyecto
make clean
make

# Crear un archivo de prueba: 
# Caso 1: 2 errores, 1 éxito, 2 errores (No debería disparar)
# Caso 2: 3 errores seguidos (Debe disparar)
echo "Ejecutando prueba de errores consecutivos..."
echo "404 500 200 403 401 503" | ./analyzer

if [ $? -eq 1 ]; then
    echo "Prueba exitosa: Alerta detectada correctamente."
else
    echo "Prueba fallida o no se encontraron 3 errores consecutivos."
fi
EOF

# Asignar permisos y ejecutar
chmod +x run.sh
./run.sh
