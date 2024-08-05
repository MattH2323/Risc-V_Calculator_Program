# Progetto calcolatore in risc-V assembly


.data

exp: .string "2-2"
contatore_parentesi: .word 0


exception_msg:           .string "Exception!: "
div_by_zero_msg:         .string "Divisione per zero!"
overflow_msg:            .string "Overflow! Impossibile calcolare:\n"
conversion_overflow_msg: .string "Overflow! Impossibile convertire operando/i!"
invalid_exp_msg:         .string "Espressione non valida!\n"
mismatched_par_exc_msg:  .string "Numero di parentesi aperte e chiuse non sono equivalenti!"

byte_position_msg:                .string "Posizione dell'errore nella string input: "




# Definisco delle costanti numeriche associate alle diverse eccezioni
Exception_handling:
    
.equ EXC_DIV_BY_ZERO, 1         # Divisore = 0
.equ EXC_OVERFLOW, 2            # Overflow
.equ EXC_CONVERSION_OVERFLOW, 3 # Overflow da conversione stringa - int
.equ EXC_INVALID_EXP, 4         # Espressione non valida
.equ EXC_PARENTHESIS, 5         # Numero di parentesi aperte e chiuse non equivalenti





.text 


Main:
    
    # Indirizzo dell'espressione con argomento
    la a0, exp
    jal Eval
    
    # Muovo il risultato dell'espressione in a0, e richiamo ecall per stampare
    mv a0, a1 
    
    li a7 1 
    ecall
    li a7 10
    ecall
            



# Funzione Eval per l'analisi di espressioni
Eval:
  
    addi sp, sp, -4
    sw ra, 0(sp)
    
    mv t0, a0      
       
    # Ottieni operando 1
    
        mv a0, t0
        jal Get_operando
        mv t0, a0
                        
        mv s1, a1
      
    # Ottieni operatore
        
        mv a0, t0
        jal Get_operatore
        mv t0, a0
        
        mv s3, a1
        
        
    # Ottieni operando 2
        
        mv a0, t0
        jal Get_operando
        mv t0, a0

        mv s2, a1 #intero
        
   
    # Calcolo
        
        # Cerco ")" o "null" per calcolare l'espressione 
        mv a0, t0 
        jal Get_risultato
        mv t0, a0    # indirizzo byte
        mv t1, a1    # risultato della sottoespressione
   
    
    # Eval_return    
    lw ra, 0(sp)     
    addi sp, sp, 4 
    mv a0, t0
    mv a1, t1
    ret
        
        



# Funzione Get_operando che accetta come argomento a0 l'indirizzo byte della stringa, restituisce a0 = indirizzo aggiornato, a1 = numero intero

Get_operando:
    
    mv t0, a0  # t0 = indirizzo byte dell'espressione

    switch_char:
        
    lb t1, 0(t0)    # Carica il byte in indirizzo t0
    addi t0, t0, 1  
    
    beqz t1, handle_null  # Se   nullo, procedi alla fine dell'analisi

    # Gestione dello spazio bianco
    li t2, 32         # Codice ASCII per spazio
    beq t1, t2, switch_char  # Se   spazio, passa al prossimo carattere

    # Gestione della parentesi aperta "("
    li t2, 40         # Codice ASCII per "("
    beq t1, t2, handle_open_parenthesis  # Se   "(", gestisci la sottoespressione racchiusa
    
    
    # Gestione dei numeri
    li a0, 4
    mv a1, t0
    li t2, 48         # Codice ASCII per '0'
    blt t1, t2, handle_exceptions  # Se non   un numero, gestisci il carattere non valido
    li t2, 57         # Codice ASCII per '9'
    bgt, t1, t2, handle_exceptions


    handle_number:
    
        # Se   un numero, gestisci l'operando
        addi t0, t0, -1   # Indirizzo byte corrente
        mv a0, t0         # Passa l'indice come parametro per la conversione
        
        addi sp, sp, -4
        sw ra, 0(sp)  # Salva ra nello stack
    
        jal String_2_int  # Converte la stringa in un numero intero
        
        lw ra, 0(sp)       # Ripristina ra
        addi sp, sp, 4     # Libera spazio nello stack
    
        mv t0, a0
        mv t1, a1
    
        j Get_operando_return     


    handle_open_parenthesis:
    
        # Incrementa il contatore delle parentesi aperte
    
        la t5, contatore_parentesi
        lw t6, 0(t5)
        addi t6, t6, 1
        sw t6, 0(t5)

        # Salva lo stato corrente e chiama ricorsivamente Eval per la sottoespressione
        addi sp, sp, -16
        sw s1, 0(sp)      # Salva op1
        sw s2, 4(sp)      # Salva op2
        sw s3, 8(sp)      # Salva operatore
        sw ra, 12(sp)     # Salva indirizzo di ritorno
    
        mv a0, t0
    
        jal Eval          # Chiamata ricorsiva per valutare la sottoespressione
        
        mv t0, a0
        mv t1, a1
        
        # Dopo il ritorno dalla chiamata ricorsiva, ripristina lo stato
        lw ra, 12(sp)     # Ripristina l'indirizzo di ritorno
        lw s3, 8(sp)      # Ripristina operatore
        lw s2, 4(sp)      # Ripristina op2
        lw s1, 0(sp)      # Ripristina op1
        addi sp, sp, 16   # Libera lo stack

        j Get_operando_return

    Get_operando_return:
    
        mv a0, t0          # Restituisce l'indice aggiornato
        mv a1, t1          # Restituisce il numero intero risultante
        ret
           




Get_operatore:
    
    mv t0, a0
    
    switch_operatore:
    
    lb t1, 0(t0)
    addi t0, t0, 1
       
    # Gestione degli operatori   
    li t2, 32
    beq t1, t2, switch_operatore
    li t2, 42         # Codice ASCII per '*'
    beq t1, t2, handle_operator # Se   '*', gestisci l'operatore
    li t2, 43         # Codice ASCII per '+'
    beq t1, t2, handle_operator # Se   '+', gestisci l'operatore
    li t2, 45         # Codice ASCII per '-'
    beq t1, t2, handle_operator # Se   '-', gestisci l'operatore
    li t2, 47         # Codice ASCII per '/'
    beq t1, t2, handle_operator # Se   '/', gestisci l'operatore 

    
    li a0, 5 
    li t2, 40         # Codice ASCII per "("
    beq t1, t2, handle_exceptions
    li t2, 41         # Codice ASCII per ")"
    beq t1, t2, handle_exceptions
    
    li a0, 4
    mv a1, t0
    li a0, 4
    j handle_exceptions
    
        
    handle_operator:
        
        mv a0, t0            # return indice
        mv a1, t1            # return operatore
        ret
    




Get_risultato:
    
    mv t0, a0  # t0 = indice stringa
    
    switch_risultato:
        lb t1, 0(t0)
        addi t0, t0, 1
        
        li t2, 32
        beq t1, t2, switch_risultato
        
        # Gestione del null 
        beqz t1, handle_null
           
        # Gestione della parentesi chiusa ")"
        li t2, 41         # Codice ASCII per ")"
        beq t1, t2, handle_closed_parenthesis  # Se   ")", gestisci la chiusura della sottoespressione
        
        
        # Eccezione
        li a0, 4
        mv a1, t0
        li a0, EXC_INVALID_EXP
        j handle_exceptions
        
    handle_closed_parenthesis:
    
        # Decrementa il contatore delle parentesi aperte
        la t5, contatore_parentesi
        lw t6, 0(t5)
        addi t6, t6, -1
        sw t6, 0(t5)

        j handle_operation

    handle_null:
    
        # Gestisce la fine dell'analisi dell'espressione
        # Controllo se il contatore di parentesi   nullo
        
        la t5, contatore_parentesi
        lw t6, 0(t5)   
        li a0, 5
        bne, t6, zero, handle_exceptions

    handle_operation:
    
        # Gestisce l'operazione successiva dopo aver identificato un operatore o concluso una sottoespressione
        mv s4, t0          # Salva l'indice corrente per l'operazione successiva

        mv a1, s1          # Passa il primo operando
        mv a2, s2          # Passa il secondo operando
        mv a3, s3          # Passa l'operatore
        
        addi sp, sp, -4
        sw ra, 0(sp)  # Salva ra nello stack

        jal Calcola         # Chiamata alla funzione Calcola per eseguire l'operazione
        
        lw ra, 0(sp)       # Ripristina ra
        addi sp, sp, 4     # Libera spazio nello stack
        
        mv t1, a1          # Salva il risultato in t1
        mv t0, s4          # Ripristina l'indice dopo l'operazione
    
    Get_result_return:
        

        mv a0, t0          # Restituisce l'indice aggiornato
        mv a1, t1          # Restituisce il numero intero risultante
        ret
            
        



Calcola:
    
     
    mv t3, a3 # carico l'operatore in t3
    
    li t2, 42 # "*"
    beq t3, t2, Mul
    li t2, 43 # "+"
    beq t3, t2, Add
    li t2, 45 # "-"
    beq t3, t2, Sub 
    li t2, 47 # "/"
    beq t3, t2, Div    
    
    
    Mul:
 
        # Inizializza i registri
        mv t0, a1        # t0 = moltiplicando
        mv t1, a2        # t1 = moltiplicatore e prodotto
        li t2, 0         # t2 = accumulatore
        li t3, 32        # t3 = contatore dei bit (32 bit per RV32I)
        li t4, 0         # t4 = bit precedente del moltiplicatore (impostato a 0)

        booth_loop:
            
            beq t3, zero, mul_overflow_check    # Se il contatore dei bit   0, esci dal ciclo

            # Determina l'operazione basata sul bit corrente e precedente del moltiplicatore
            andi t5, t1, 1              # Ottieni il bit corrente del moltiplicatore (t5 = t1 & 1)
            sub t6, t4, t5              # bit precedente - bit corrente

            beq t6, zero, shift_right   # Se corrente - precedente == 0, non fare nulla
            blt t6, zero, subtract      # Se corrente - precedente < 0, sottrai
            add t2, t2, t0              # Se corrente - precedente > 0, aggiungi il moltiplicando all'accumulatore
            j shift_right


        subtract:
            
            sub t2, t2, t0              # Sottrai il moltiplicando dall'accumulatore

        shift_right:
    
            andi t6, t2, 1              # Estraggo l'ultimo bit dell'accumulatore
            slli t6, t6, 31             # muovo il bit alla testa del registro
            srai t2, t2, 1              # Sposta l'accumulatore a destra (aritmetico)
        
    
            srli t1, t1, 1              # Sposta il moltiplicatore a destra (logico)
            or t1, t1, t6               # modifico esclusivamente il 32esimo bit
     
            mv t4, t5                   # Aggiorna il bit precedente con il bit corrente del moltiplicatore
            addi t3, t3, -1             # Decrementa il contatore dei bit
            j booth_loop

        mul_overflow_check:        
            #se uno dei bit dell'accumulatore   diverso dal primo bit del registro prodotto, allora overflow
           
            or t0, t1, t0               # Ricopio il registro
            srai t0, t0, 31             # Estraggo il primo bit
            beqz t0, mul_bit_0          # Verifico se   0 o 1
            
                mul_bit_1:
                    
                    li t3, 0
                    addi t3, t3, -1
                    beq t3, t2, mul_no_overflow
                    j mul_overflow
                    
                mul_bit_0:
                    
                    beq t2, zero, mul_no_overflow
                    j mul_overflow
                    
                    
            mul_overflow:
                
                beqz a3, conversion_overflow   # Se a3 = 0, implica che   un overflow dovuto a String_2_int
                li a0, 2
                j handle_exceptions
                
                         
            mul_no_overflow:
            
            mv a1, t1
            ret
            
            

        
    Add:
        
        add t1, a1, a2  # add
        
        add_overflow_check:
            
            blt t1, zero,  add_somma_neg
                        
            add_somma_pos: 
            # Se entrambi gli operandi sono negativi, allora overflow
                
                blt a1, zero, add_op1_neg 
                j add_no_overflow   
                  
                add_op1_neg:          
                # Se op2   negativo, overflow 
                             
                    blt a2, zero add_overflow
                    j add_no_overflow
                             
            add_somma_neg: 
            # Se entrambi gli operandi sono positivi, allora overflow
                
                bge a1, zero, add_op1_pos
                j add_no_overflow 
                        
                add_op1_pos:          
                # Se op2   positivo, overflow 
                          
                    bge a1, zero, add_overflow
                    j add_no_overflow
                    
                    
        add_overflow:
            
            beqz a3, conversion_overflow   # Se a3 = 0, implica che   un overflow dovuto a String_2_int
            li a0, 2
            j handle_exceptions
            
                       
        add_no_overflow:    
        
            mv a1, t1
            ret
 
        
    Sub:
        
        sub t1, a1, a2
        
        sub_overflow_check:
            
            blt t1, zero,  sub_differenza_neg
                        
            sub_differenza_pos: 
            # Se op1 < 0 e op2 >= 0, allora overflow
                
                blt a1, zero, sub_op1_neg 
                j sub_no_overflow     
                
                sub_op1_neg:          
                # Se op2   positivo, overflow
               
                    bge a2, zero sub_overflow
                    j sub_no_overflow
                             
            sub_differenza_neg: 
            # Se op1 >= 0 e op2 < 0, allora overflow
                
                bge a1, zero, sub_op1_pos
                j sub_no_overflow    
     
                sub_op1_pos:          
                # Se op2   negativo , overflow    
                                          
                    blt a2, zero, sub_overflow
                    j sub_no_overflow
                    
                    
        sub_overflow:
            
            li a0, 2                 
            j handle_exceptions
                                
        sub_no_overflow:    
        
        mv a1, t1
        ret
        
        
              
        
    Div:
        
        
        # Inizializza i registri
        mv t0, a1        # t0 = dividendo e quoziente 
        mv t1, a2        # t1 = divisore
        li t2, 0         # t2 = accumulatore
        li t3, 32        # t3 = contatore dei bit (32 bit per RV32I)
        
        # Divisore = 0
        li a0 1
        beqz t1, handle_exceptions

        
        li t5, 1
        li t6, -1  
        
        # Se uno degli operandi di DIV   negativo, allora risultato   negativo    
        dividendo_segno:
            
            bge t0, zero, divisore_segno
            mul t0, t0, t6
            mul t5, t5, t6
            
        divisore_segno:
            
            bge t1, zero, div_loop
            mul t1, t1, t6
            mul t5, t5, t6
                
            
        div_loop:
            
            beq t3, zero, div_done    # Se il contatore dei bit   0, esci dal ciclo

            slli t2, t2, 1  # left-shift accumulatore
            or t4, t0, zero # copio il quoziente
            srli t4, t4, 31 # estraggo il bit che era in testa
            or t2, t2, t4   # lo ricopio in fondo al registro accumulatore
            
            slli t0, t0, 1  # left-shift quoziente       
            sub t2, t2, t1  # accumulatore = accumulatore - divisore
            
            blt t2, zero, div_neg

                div_pos:
                    ori t0, t0, 1
                    j next_loop
                               
                div_neg:
                    add t2 , t2, t1
                         
            next_loop:
                addi t3, t3, -1
                j div_loop
        
        
        div_done:
            
            mul t0, t0, t5
            mv a1, t0
            ret
            
        
        
                 

String_2_int:
    
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Inizializzo   
    li t1, 0             # Intero 
    mv t0, a0            # Indice Stringa
        
    read_digits:
    
        lb t3, 0(t0)         # Carica il byte
        
        # Se non   un numero, fine
        li t2, 48
        blt t3, t2, fine_conversione     # Se il valore ASCII < 48, allora non   un numero
        li t2, 58
        bgt t3, t2, fine_conversione     # Se il valore ASCII > 58, allora non   un numero


        # Converto il byte e aggiorno il risultato
        # Per le operazioni di addizione e moltiplicazione, utilizzo ADD e MUL per controllare eventuali overflow da conversiome
        
        li t2, 48           
        sub t3, t3, t2      # Convertire da ASCII a valore numerico

        li a3 , 0           # a3 = 0,   un flag, utile in caso di overflow da operazioni di ADD o MUL
        
        # Moltiplico t4 per 10
        mv s4, t0           # Salvo l'indice
        mv s5, t3           # Salvo il char
        
        mv a1, t1           
        li a2, 10
        
        jal Mul             # mul t4, t4, t3 |  t4 = t4 * 10
        mv t1, a1  
              
        mv t0, s4           # Recupero l'indice
        mv t3, s5           # Recupero il char
 
        
        # Sommo t1 al risultato                    
        mv s4, t0           # Salvo l'indice
        
        mv a1, t1           # Int 
        mv a2, t3           # Ultima cifra convertita
        
        jal Add             # mul t4, t4, t3 |  t4 = t4 * 10     
        mv t1, a1           
               
        mv t0, s4           # Recupero l'indice
        
        next_digit:
            
            addi t0, t0, 1       # Prossimo byte
            j read_digits
            
            
            
    conversion_overflow: 
                   
        li a0, EXC_CONVERSION_OVERFLOW
        j handle_exceptions
        
                    
    fine_conversione:
                
        # ritorno l'indice della stringa e il numero convertito    
        mv a0, t0          # indice 
        mv a1, t1          # intero 
        
        lw ra, 0(sp)
        addi sp, sp, 4
        
        ret

  
  
  
handle_exceptions:
    
    mv t1, a0
    
    la a0, exception_msg
    li a7, 4
    ecall
    
    switch_exception:
    # In base al valore di t1, verr  lanciata un'eccezione diversa
         
        li t0, EXC_DIV_BY_ZERO
        beq t1, t0, handle_div_by_zero
         
        li t0, EXC_OVERFLOW
        beq t1, t0, handle_overflow
         
        li t0, EXC_CONVERSION_OVERFLOW
        beq t1, t0, handle_conversion_overflow 
           
        li t0, EXC_INVALID_EXP
        beq t1, t0, handle_invalid_exp
         
        li t0, EXC_PARENTHESIS
        beq t1, t0, handle_mismatch_par
         
         
         
        exit:
             
            li a7, 10
            ecall
            
    
    handle_div_by_zero:
    
        la a0, div_by_zero_msg
        li a7, 4
        ecall
        
        j exit 
        
    handle_overflow:
         
        # a1 = op1
        # a2 = op2
        # a3 = operatore
        
        la a0 overflow_msg 
        li a7, 4
        ecall
        
        mv a0, a1   
        li a7, 1
        ecall
        
        mv a0, a3
        li a7, 11
        ecall
        
        mv a0, a2
        li a7, 1
        ecall
        
        j exit
        
        
              
    handle_conversion_overflow:
        
        la a0, conversion_overflow_msg      
        li a7, 4
        ecall
        
        j exit
        
        
    handle_invalid_exp:
        
        mv t0, a1
        la t1, exp
        sub t0, t0, t1
        
        la a0 invalid_exp_msg 
        li a7, 4
        ecall
        
        la a0 byte_position_msg
        li a7, 4
        ecall
        
        mv a0, t0
        li a7, 1
        ecall
        
        j exit
        
      
    handle_mismatch_par:
        
        la a0, mismatched_par_exc_msg
        li a7, 4
        ecall
        
        j exit
        
        
    
