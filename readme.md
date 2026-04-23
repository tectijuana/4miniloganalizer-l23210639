# 🎓 Tecnológico Nacional de México
## 🏫 Instituto Tecnológico de Tijuana
**Subdirección Académica** **Departamento de Sistemas y Computación** **Ingeniería en Sistemas Computacionales**

---

**📑 LENGUAJES DE INTERFAZ** **👨‍🏫 Profesor:** MC. René Solis Reyes  
**📅 Semestre:** Ene - Jun 2026  

---

**📝 Práctica Bloque:** Implementación de un Mini Cloud Log Analyzer en ARM64  
**🎯 Objetivo:** Diseñar una solución en ensamblador para detectar 3 errores HTTP consecutivos (4xx/5xx).  
**👤 Estudiante:** Ornelas Torres Juan Carlos  
**🆔 Número de Control:** 23210639  

---

### 📖 Explicación del Algoritmo
Para cumplir con la detección de **3 errores consecutivos**, el programa sigue esta lógica:
1.  **Monitoreo:** Se usa el registro `X10` como contador de "racha".
2.  **Detección de Errores:** Si el primer dígito de un código es '4' o '5', se suma 1 a `X10`.
3.  **Reinicio por Éxito:** Si aparece cualquier otro número (como el '2' de un 200 OK), el registro `X10` se limpia (`mov x10, #0`). Esto garantiza que solo se dispare la alerta si los fallos ocurren uno tras otro.
4.  **Alerta:** Al llegar a 3 en el contador, se emite el mensaje crítico por consola.

---

### 💻 Implementación de Código (Todo en uno)

#### 📄 1. Código Fuente (`analyzer.s`)
```assembly
.data
    msg_alert:  .ascii "\n⚠️  [ALERTA CRÍTICA] Se detectaron 3 errores consecutivos!\n"
    len_alert:  .quad 60
    buffer:     .byte 0

.text
.global _start

_start:
    mov x10, #0          // 🔢 Inicializar contador de errores consecutivos

read_char:
    // 📥 Syscall read(stdin, buffer, 1)
    mov x0, #0           
    ldr x1, =buffer      
    mov x2, #1           
    mov x8, #63          
    svc #0

    // 🛑 Verificar fin de archivo (EOF)
    cmp x0, #0
    ble exit_normal

    ldrb w2, [x1]        // 📥 Cargar byte leído

    // 🔍 Filtro: Solo procesar dígitos numéricos ASCII (0-9)
    cmp w2, #'0'
    blo read_char
    cmp w2, #'9'
    bhi read_char

    // 🚥 Lógica de detección: ¿Es error? (4xx o 5xx)
    cmp w2, #'4'
    b.eq increment_error
    cmp w2, #'5'
    b.eq increment_error

    // ✅ SI NO ES ERROR: Reiniciar racha (rompe la consecutividad)
    mov x10, #0
    b read_char

increment_error:
    add x10, x10, #1     // ➕ Aumentar racha de errores
    cmp x10, #3          // 🚨 ¿Llegamos al límite crítico?
    b.ge trigger_alert
    b read_char          

trigger_alert:
    // 📢 Imprimir alerta mediante syscall write
    mov x0, #1           
    ldr x1, =msg_alert   
    ldr x2, =len_alert   
    ldr x2, [x2]         
    mov x8, #64          
    svc #0
    
    mov x0, #1           // 🚩 Salida con estado de alerta (1)
    mov x8, #93          
    svc #0

exit_normal:
    mov x0, #0           // ✨ Salida estándar (0)
    mov x8, #93
    svc #0


MARKFILE
AS = as
LD = ld
TARGET = analyzer

all: $(TARGET)

$(TARGET): analyzer.o
	$(LD) -o $(TARGET) analyzer.o

analyzer.o: analyzer.s
	$(AS) -o analyzer.o analyzer.s

clean:
	@echo "🧹 Limpiando archivos temporales..."
	rm -f $(TARGET) *.o


SCRIPT

#!/bin/bash
# Dar permisos con: chmod +x run.sh

echo "🔨 Compilando el analizador ARM64..."
make clean
make

# 🧪 Simulación de logs: 2 errores, un éxito (200) y 3 errores seguidos.
LOG_DATA="404 500 200 403 503 500"

echo -e "\n🔍 Analizando flujo de logs en tiempo real..."
echo "📥 Entrada: $LOG_DATA"
echo "$LOG_DATA" | ./analyzer

if [ $? -eq 1 ]; then
    echo -e "\n✅ Resultado: Alerta generada (Prueba Superada)."
else
    echo -e "\n❌ Resultado: No se detectaron 3 errores seguidos."
fi
