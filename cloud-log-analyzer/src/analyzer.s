.data
    msg_alert:  .ascii "\n⚠️  [ALERTA CRÍTICA] Se detectaron 3 errores consecutivos!\n"
    len_alert:  .quad 60
    buffer:     .byte 0

.text
.global _start

_start:
    mov x10, #0          // Contador de errores

read_char:
    mov x0, #0           
    ldr x1, =buffer      
    mov x2, #1           
    mov x8, #63          
    svc #0

    cmp x0, #0           
    ble exit_normal

    ldrb w2, [x1]        

    // Si es un espacio o salto de línea, ignorar y seguir leyendo
    cmp w2, #32
    b.eq read_char
    cmp w2, #10
    b.eq read_char

    // ¿Es error? (4xx o 5xx)
    cmp w2, #'4'
    b.eq increment_error
    cmp w2, #'5'
    b.eq increment_error

    // Si es un '2' o cualquier otro, resetear contador
    mov x10, #0
    b read_char

increment_error:
    add x10, x10, #1     
    cmp x10, #3          
    b.ge trigger_alert
    b read_char          

trigger_alert:
    mov x0, #1           
    ldr x1, =msg_alert   
    ldr x2, =len_alert   
    ldr x2, [x2]         
    mov x8, #64          
    svc #0
    
    mov x0, #1           
    mov x8, #93          
    svc #0

exit_normal:
    mov x0, #0           
    mov x8, #93
    svc #0
