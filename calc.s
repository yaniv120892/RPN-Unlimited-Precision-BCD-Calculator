%macro startFunc 0
	push ebp
	mov ebp,esp
%endmacro

%macro endFunc 0
	mov esp,ebp
	pop ebp
	ret
%endmacro



%macro errorInput 0
	push error_input
	push format_string
	call printf
	add esp,8
%endmacro

%macro errorOverflow 0
	push error_overflow
	push format_string
	call printf
	add esp,8
%endmacro

%macro errorNotEnoughArgument 0
	push error_not_enough_arguments
	push format_string
	call printf
	add esp,8
%endmacro

%macro errorExponent 0
	push error_exponent
	push format_string
	call printf
	add esp,8
%endmacro

%macro printDebug 1
	push %1
	push dword[stderr]
	call fprintf
	add esp,8
%endmacro


%macro CheckToPrintDebug 1
        cmp byte[has_Debug], 0
        je %%EndCheckToPrintDebug
	printDebug %1
	%%EndCheckToPrintDebug:
	
%endmacro


%macro printEndMsg 0
	push dword[counter_operation] 
	push format_number
	call printf
	add esp,8
%endmacro

extern exit 
extern printf 
extern fprintf 
extern malloc 
extern free
extern fgets 
extern stderr 
extern stdin 
extern stdout

section .rodata
        StartProgram:
                DB "Entering my_calc function" , 10 , 0
        MsgAddFunc:
                DB "Entering add function" , 10 , 0       
        MsgShlFunc:
                DB "Entering shift left function" , 10 , 0        
        MsgShrFunc:
                DB "Entering shift right function" , 10 , 0       
        MsgDupFunc:
                DB "Entering duplicate right function" , 10 , 0
        MsgPrintFunc:
                DB "Entering print and pop function" , 10 , 0
        EndProgram:
                DB "Existing main function, bye bye" , 10 , 0
                
	print_data_format:
     DB   "%02X", 0   ; with leading zero

	print_data_format_without_zero:
     DB   ">>%X", 0   ; no leading zero
	format_string:
		DB "%s",0 ;string format
	format_number:
		DB "%d",10,0 ;number format
	string_input:
		DB ">>calc: ",0 ;the string for input in the calculator
	string_output:
		DB ">>",0 ;the result of the calculator	
	error_overflow:
		DB ">>Error: Operand Stack Overflow",10,0 	
	error_exponent:
		DB ">>Error: exponent too large",10,0 	
	error_not_enough_arguments:
		DB ">>Error: Insufficient Number of Arguments on Stack",10,0 ;
	error_input:
		DB ">>Error: invalid input",10,0 ;
	check_string:
		DB "check_string",10,0 ;
	aaa:
		DB "aaa",10,0 ;
	bbb:
		DB "bbb",10,0 ;
	ccc:
		DB "ccc",10,0 ;
	Input_is_number:
		DB "Input is number",10,0 ;
	Input_Is_Command:
			DB "Input is command",10,0 ;
	enterNumberToStack:
			DB "Enter number to the stack",10,0 ;
	newline:
			DB "",10,0 ;
	Msg_Number_Of_Operations:
			DB "Number Of Operations is %d" ,10,0 ;
	Msg_Odd_Length:
				DB "length is odd " ,10,0 ;
	Msg_Even_Length:
				DB "length is even ", 10,0 ;
	NODE_SIZE equ 5 ; represent pointer and data
	MAX_STACK_SIZE equ 5; saves the max stack size
	NODE_DATA equ 0
	NODE_NEXT_POINTER equ 1

	
section .bss
	input RESB 80 ;input from the user  need to understand what is this stupid sections?!?!?!?
	input_length RESB 1 ;the length of the input
	head_link  RESB 4 
	CALC_STACK:  RESD   MAX_STACK_SIZE  ;the stack we will use in the calculator (size 5)\

section .data
        carry_next DD 0 ; contains the carry for the high nibble for shr
        carry_prev DD 0 ; contains the carry for the high nibble for shr
        result_Hex_Divided DD 0 ; contains the result of division by 2
        counter_shift DD 0  ;counter containg how many left to shift
	counter_link DD 0 
	counter_operation DD 0 ;counter of operations
	counter_stack_size DD 0 ; counter of the stack operands
	add_zero DD 0         ;boolean number that tell us if we need to add zero to the number that wes given by the user
	counter_nodes DD 0
	remove_node DD 0 ; saves if to remove this node from his previous
	has_Debug DD 0

section .text 
	align 16 
    global main 
	
;-------------------------------------------------------------------------------------------
main:


	push ebp
	mov ebp, esp

	mov ecx	,dword [ebp + 4 + 1*4]	; ecx <-- argc
	mov ebx, dword [ebp + 4 + 2*4] ; argv[]
	mov edx, 0		       ; arg index
.loop:
        cmp edx, ecx		; stop when index = argc
	jge start_main
        mov eax, 0
        mov eax ,dword[ebx+edx*4] 
        inc edx			; next arg
        cmp byte[eax+0], '-'
        jne .loop
        cmp byte[eax+1] , 'd'
        jne .loop 
	mov byte[has_Debug], 1
		
	
	
	start_main:
	CheckToPrintDebug StartProgram
	call my_calc ;start the calculator 

Exit_Program:
        CheckToPrintDebug EndProgram
	printEndMsg
	mov eax,1 ;exit code 1
        mov ebx,0 ;
        int 0x80 ;give control to kernel to run exit

;-------------------------------------------------------------------------------------------
my_calc:
    mov byte [add_zero],0
    mov byte [counter_link],0
    mov byte [counter_nodes],0


    startFunc
 
    push string_input ; >>calc: sent as argument to printf
    push format_string ; string format
    call printf  ; calling printf
    add esp,8

    call get_input ; gets the input of the user into input and its length into input_length
    jmp my_calc
	
;-------------------------------------------------------------------------------------------	
	

get_input:
    startFunc
    mov ecx, input
    push dword[stdin]  ; read from stdin
    push 80   ; max 80 chars
    push ecx  ; input of the user
    call fgets
    add esp,12
	
    cmp byte[input],0  ; if the input is null we ignore it and start over
    je my_calc
	
    cmp byte[input],48  	;check if it is a number or something else
    jb input_is_not_number            ;jump for case it is not a number
    cmp byte[input],57  ;check if it a char above the number asci
    ja input_is_not_number            ;jump to the place where we deal with no number letters
	
	;We are number
input_is_number:

	CheckToPrintDebug Input_is_number
	cmp byte[counter_stack_size] , MAX_STACK_SIZE
	je errorOverflowFunc

	pushad
	mov byte[add_zero] , 0
	push input
	call get_length_of_inputFunc
	add esp, 4
	mov byte[input_length] , 0
	
;;;Added to fix the length!!!!!!!!!-----------------------------------------------------
	sub eax , 1
;;;Added to fix the length!!!!!!!!!-----------------------------------------------------

	mov dword[input_length] , eax
	
	
	
	popad
	mov ebx, input
	; check even or odd in order to know if to add zero
	mov eax , dword[input_length]
	mov cl , 2
	div cl
	cmp ah, 1
	je odd
	CheckToPrintDebug Msg_Even_Length
	jmp parse_number
	
	
odd:
     CheckToPrintDebug Msg_Odd_Length
     mov byte [add_zero],1
     jmp parse_number
	
	
	endFunc
;-------------------------------------------------------------------------------------------
parse_number:
     mov eax,0								
     cmp byte[add_zero],1					
     je parse_odd_number					
     mov edx,1								
     jmp parse_loop							

parse_odd_number:							
    mov edx,2								
     
parse_loop:
     mov ecx,0								
     cmp byte [ebx],0xa ; get to the end of the input
     je enter_stack							

     cmp byte[ebx],'9'       
     jle char_is_less_then_9
	 
     jmp errorInputFunc        

enter_list:
     cmp edx,1
     je firstDigit                 ; it is the first char in the couple
     jmp secondDigit              ; it is the second char in the couple

	
char_is_less_then_9:                  
     cmp byte[ebx],'0'        
     jl errorInputFunc
     sub byte[ebx],'0'        ; if it is a digit we subtract the ascii value of 0 from it to have the actual number
     jmp enter_list           ; jump to enter the number

firstDigit:                        ; the first digit to add to the data of the link
     mov al,byte[ebx]        
     mov cl,4                 
     shl al,cl               
     inc edx                  
     inc ebx               
     jmp parse_loop           

secondDigit:                       ; the second number to add to the data of the link
     mov ah,byte[ebx]         
     add al,ah                
     mov edx,1                
     inc ebx                  
     pushad                   ; backup registers
     push eax                 ; push argument 1 for create_link function
     call create_link         ; call the function (to create the link)
     add esp,4                ; delete the function argumant
     popad                    ; restore registers
     mov eax,0                ; initialize eax for next couple of numbers
     jmp parse_loop           ; return to the loop that parse the input	
	
	
		
;------- create a link in the list of the number----------------
create_link:
     startFunc
     mov ecx,[ebp+8]          ; get the first argument (the data of the link)
     cmp cl,0                 ; checks if it is a couple of 00
     je check_zeros			  ; if it is 2 zeros we will check if they are the first we ignore else we enter them to the list
continue_link:
     push ecx                 ; backup the register ecx that holds tha data
     push NODE_SIZE               ; push the size of the link we want 5 
     call malloc              
     add esp,4
     pop ecx                  ; restore ecx
check1:
     mov [eax+NODE_DATA],cl             ; put in the first byte of the link (pointed by eax) the data
     cmp byte [counter_nodes],0 ; check if this is the first link in the list
     je first_link
     jmp next_link

first_link:                             ; make the first link
     mov ebx, dword[counter_nodes]        ; these three lines increase the conter of links in the list by one
     inc ebx
     mov [counter_nodes],dword ebx
     mov dword[eax + NODE_NEXT_POINTER],0                 ; make the pointer for next link null because this link is the first
     mov [head_link],eax                     ; make head point to this link
     jmp end_link

next_link:                              ; make link
     mov ebx,dword[head_link]                ; make ebx hold the address of the head os the list
     mov [eax+NODE_NEXT_POINTER], ebx                  ; new link now will point to the head of the list
     mov dword[head_link],eax                ; make the head point to this link now
     jmp end_link
end_link:
	 endFunc

check_zeros: 				 			; checks if there are leading zeros
	cmp byte [counter_nodes],0 			; check if this is the first link in the list
	je check_if_zero					; check maybe the number is just 0
	jmp continue_link					; the zeros are part of the nuber so we create for them a link

check_if_zero:							; check if the number is 0
	cmp byte[input_length],1 					; check if the length of the number is 1 then the number have to be 0
	je continue_link					; if the number is 0 we aad it to the stack (CALC_STACK)
	jmp end_link						; the number is not 0 it is only a leading zero so we dont add it to the list

;----------------enter the list of numbers to the array (stack)------------------------
enter_stack:  
     CheckToPrintDebug enterNumberToStack
     mov esi,0                               
     mov dword esi, [counter_stack_size]         
     mov ebx,dword [head_link]
     mov [CALC_STACK + esi*4],dword ebx		; inserting the list of the numbers pointed by head (now in ebx) to the right place (according to the number of elements in the stack)
     inc esi								; increase the number of elements in the stack by 1
     mov dword [counter_stack_size],esi
     mov dword [head_link],0						; reset the pointer head for the next number
     mov dword [counter_nodes],0				; reset the counter of links in a list for the next number
     jmp my_calc							; return to the main loop




;-------------------------------------------------------------------------------------------
	
get_length_of_inputFunc:
	startFunc
	mov ebx , [ebp+8]
	mov eax, 0
	
	start_loop_get_length:
		cmp byte[ebx] , 0 ; check if we got to end of input
		je end_loop_get_length
		inc ebx
		inc eax
		jmp start_loop_get_length
	
	end_loop_get_length:
		endFunc
;-------------------------------------------------------------------------------------------


input_is_not_number:


        CheckToPrintDebug Input_Is_Command

	check_add:
		cmp byte[input],'+'  ; if the command is +     
		jne check_print_and_pop
		call addFunc                  ; call to the command that adds the numbers
		jmp my_calc
	check_print_and_pop:
		cmp byte[input],'p'  ; if the command is pop and print
		jne check_duplicate
		call print_and_popFunc                  ; jump to the command that pop and print a number
		jmp my_calc
	check_duplicate:
		cmp byte[input],'d'  ; if the command is duplicate  
		jne check_shl
		call duplicateFunc              ; jump to the command that duplicate
		jmp my_calc
	check_shl:
		cmp byte[input],'l'  ; if the command is shift left
		jne check_shr
		call shlFunc                 ; jump to the command that performs shift left
		jmp my_calc
	check_shr:
		cmp byte[input],'r'  ; if the command is shift right
		jne Quit
		call shrFunc           ; jump to the command that performs shift right
		jmp my_calc
	Quit:
                cmp byte[input],'q'  ; quit if needed
		je quitFunc
		
        jmp my_calc
		
;----------------------------------Quit---------------------------------------------------------
quitFunc:
    jmp Exit_Program
	
;---------------------------------Shift Right-------------------------------------------------------------------------


shrFunc:
    startFunc
    CheckToPrintDebug MsgShrFunc
    
    cmp byte[counter_stack_size] ,1 ; check if there are numbers in the stack for Addition.
    jle errorNotEnoughArgumentFunc
    
    
    mov esi, 0
    mov esi , dword[counter_stack_size]
    mov ebx , [CALC_STACK + esi*4 - 4] ; the shift right number
    cmp dword[ebx+NODE_NEXT_POINTER],0
    jne errorExponentFunc
    mov ebx, [ebx+NODE_DATA]
    mov dword[counter_shift],ebx
    dec esi                             ; increase number of elements in stack
    mov dword[counter_stack_size], esi
    
    mov ebx , 0
    mov ebx , dword[counter_operation]
    inc ebx                             ; increase number of operations
    mov dword[counter_operation] , ebx
    
    mov ebx , [CALC_STACK + esi*4 - 4] ; the number to shift 

    mov ecx, dword[ebx+NODE_DATA]
    
    shrFuncLoop:                        ; the loop to subtract each time
        cmp dword[counter_shift],0      ; if counter_shift is 0 then we finished shifting
        je endShrFuncLoop
        
        clc
        push ebx
        call divide_number_by_two 
        pop ebx
        clc
        
        mov ecx,dword[counter_shift]
        mov esi,0x0f
        and esi,ecx
        cmp esi,0
        jne continueShrFunc
        
        sub ecx,6
        
        continueShrFunc:
        dec ecx
        
        mov dword[counter_shift],ecx
        jmp shrFuncLoop
    
endShrFuncLoop:
    mov dword[counter_shift], 0        ; initialize for the next time
    
    push ebx
    
    call remove_leading_zero
    
    

    
    
    endFunc

    
remove_leading_zero:
    startFunc
    
    mov ebx , [ebp+8]
    cmp dword[ebx+NODE_NEXT_POINTER],0
    je check_if_zero2
    push ebx
    push dword[ebx+NODE_NEXT_POINTER]
    call remove_leading_zero
    add esp , 4
    pop ebx
    cmp byte[remove_node], 1
    jne End_remove_leading_zero
    
    ;need to change the next node to null(next node is 00)
    mov dword[ebx+NODE_NEXT_POINTER], 0
    mov byte[remove_node], 0
    
    
    check_if_zero2:
        cmp byte[ebx+NODE_DATA], 0
        je Need_To_Remove
        endFunc
        
        Need_To_Remove:
            mov byte[remove_node], 1
            endFunc
        
        
    
    
    End_remove_leading_zero:
            endFunc
    
    
    
    

divide_number_by_two:
    startFunc
    mov ebx,[ebp+8]
    cmp dword[ebx+NODE_NEXT_POINTER],0
    jne divideNormalNode
    
    push ebx
    call divide_hex_by_2
    pop ebx
    mov eax , dword[result_Hex_Divided]
    mov byte[ebx+NODE_DATA], al
    endFunc
    
    divideNormalNode:
        
        push ebx
        mov ebx,dword[ebx+NODE_NEXT_POINTER]
        push ebx
        call divide_number_by_two
        add esp, 4
        pop ebx

        
        push ebx
        call divide_hex_by_2
        pop ebx
        mov eax , dword[result_Hex_Divided]
        
        cmp byte[carry_prev],0
        je No_Carry_To_Add
        add eax, 0x50
        daa 
        mov byte[carry_prev] , 0
        
        No_Carry_To_Add:
        mov byte[ebx+NODE_DATA], al
        endFunc
        
        
divide_hex_by_2:
    startFunc
    
    mov esi, [ebp+8]
    
    mov dl,0
    mov dl,byte[carry_next]
    mov byte[carry_prev], dl
    mov byte[carry_next] , 0
    
    mov esi , [esi+NODE_DATA]
    mov ecx , 0xf0
    and ecx , esi
    

    
    mov edx ,0
    shr ecx,4
    times 10 add edx ,ecx
    
    mov ecx , 0x0f
    and ecx , esi
    
    add edx , ecx
    
    
    mov eax ,0
    mov eax , edx
    mov cl , 2
    div cl
    cmp ah, 1
    jne Even_Number
    
    mov byte[carry_next],1
    jmp after_check_even_or_odd
    
    Even_Number:
    mov byte[carry_next],0
    
    
    
    after_check_even_or_odd:
    shr edx , 1
    ;jnc No_Carry_After_Shift
    ;mov byte[carry_next],1
    
    ;No_Carry_After_Shift:
    
    cmp edx, 10
    jl end_divide_hex_by_2
    
    mov eax , edx
    mov ecx , 10
    div cl
    shl al, 4
    mov ebx,0
    mov bl, ah
    add bl,al
    mov edx, ebx
    
    
    end_divide_hex_by_2:
        mov dword[result_Hex_Divided] , edx
        endFunc
    
    

;---------------------------------Shift Left-------------------------------------------------------------------------


shlFunc:
    startFunc
    CheckToPrintDebug MsgShlFunc
    cmp byte[counter_stack_size] ,1 ; check if there are numbers in the stack for Addition.
    jle errorNotEnoughArgumentFunc
    
    mov ebx , 0
    mov ebx , dword[counter_operation]
    inc ebx                             ; increase number of operations
    mov dword[counter_operation] , ebx
    
    mov esi, 0
    mov esi , dword[counter_stack_size]
    dec esi                             ; increase number of elements in stack
    mov dword[counter_stack_size], esi
    
    mov ebx , [CALC_STACK + esi*4] ; the shift right number 
    cmp dword[ebx+NODE_NEXT_POINTER],0
    je start_shl
    
    Restore_stackSize_shl:
        mov esi, 0
        mov esi , dword[counter_stack_size]
        inc esi                             ; increase number of elements in stack
        mov dword[counter_stack_size], esi
        
        mov ebx , 0
        mov ebx , dword[counter_operation]
        dec ebx                             ; decrease number of operations
        mov dword[counter_operation] , ebx
        jmp errorExponentFunc
        
    start_shl:
    
    mov ecx, dword[ebx+NODE_DATA]
    mov dword[counter_shift],ecx
    
    
    
    shlFuncLoop:                        ; the loop to subtract each time
        cmp dword[counter_shift],0      ; if counter_shift is 0 then we finished shifting
        je endShlFuncLoop
        
        pushad
        call duplicateFunc
        popad
        mov ebx,dword[counter_operation]
        dec ebx
        mov dword[counter_operation],ebx
        
        pushad
        call addFunc
        popad
        
        mov ebx,dword[counter_operation]
        dec ebx
        mov dword[counter_operation],ebx
        
        mov ebx,dword[counter_shift]
        mov esi,0x0f
        and esi,ebx
        cmp esi,0
        jne continueShlFunc
        
        sub ebx,6
        
        continueShlFunc:
        dec ebx
        
        mov dword[counter_shift],ebx
        jmp shlFuncLoop
    
endShlFuncLoop:
    mov dword[counter_shift], 0        ; initialize for the next time
    endFunc
    

;---------------------------------Duplicate-------------------------------------------------------------------------

duplicateFunc:
    
    startFunc
    CheckToPrintDebug MsgDupFunc
    cmp byte[counter_stack_size] ,0 ; check if there are numbers in the stack.
    je errorNotEnoughArgumentFunc
	
    cmp byte[counter_stack_size] ,MAX_STACK_SIZE ; check if there is space in the stack for more elements.
    je errorOverflowFunc
    
    mov ebx , 0
    mov ebx , dword[counter_operation]
    inc ebx ; increase 	number of operations
    mov dword[counter_operation] , ebx
    
    mov eax,0
    mov ebx,0
    mov esi,0
	
	
    mov esi , dword[counter_stack_size] ; increase the number of elements in the stack.
    mov ebx , [CALC_STACK + esi*4 -4] ; saves the first node of the element to duplicate
    
    inc esi
    mov dword[counter_stack_size], esi
    dec esi
	
    push NODE_SIZE
    call malloc
    add esp,4
	
    mov [CALC_STACK + esi*4], eax ; saves the new node
    
    Duplicate_Node:
        mov ecx, 0
        mov cl , [ebx + NODE_DATA] ; copy the data
        mov [eax +NODE_DATA], cl
        mov dword[eax+NODE_NEXT_POINTER],0
        
		
        cmp dword[ebx+NODE_NEXT_POINTER] , 0
        je End_Duplicate
        mov ebx,[ebx + NODE_NEXT_POINTER]
        mov edx, 0
        mov edx,eax
        push edx
        push NODE_SIZE
        call malloc
        add esp,4
        pop edx
        
        mov [edx+NODE_NEXT_POINTER], eax
        mov edx , [edx+NODE_NEXT_POINTER]

		
        jmp Duplicate_Node
	
	
	
	End_Duplicate:
            endFunc
	
	
;---------------------------------Print And Pop-------------------------------------------------------------------------

print_and_popFunc:
    startFunc
    CheckToPrintDebug MsgPrintFunc
    cmp byte[counter_stack_size] ,0 ; check if there are numbers in the stack.
    je errorNotEnoughArgumentFunc
    mov ebx , 0
    mov ebx , dword[counter_operation]
    inc ebx ; increase 	number of operations
    mov dword[counter_operation] , ebx
	
    mov eax, 0
    mov ebx , 0
    mov eax, dword[counter_stack_size] ; remove a number from the stack.
    dec eax
    mov ebx,dword[CALC_STACK+eax*4]					
    mov dword[counter_stack_size], eax
	
    mov ecx , 0
    mov cl , [ebx + NODE_DATA] ;
    mov ebx , dword[ebx + NODE_NEXT_POINTER]
	
    cmp ebx,0                                    ; check if this link points to null (if this is the only link in the list)
    je Print_One_Node
    pushad
    push ebx
    call Print_Nodes
    add esp,4
    popad   
	
Print_Last_Node:
    push ecx                                     ; push ecx which contains the data for printing
    push print_data_format                              ; push the format of printing
    call printf
    add esp,8
    push newline                                 ; this is the end of the number so we print a newline marker
    call printf
    add esp,4
    endFunc
	
	
	
	
	
	
Print_One_Node:
    push ecx                                     ; push ecx which contains the data for printing
    push print_data_format_without_zero                        ; push the format of printing without leading zero
    call printf
    add esp,8
    push newline                                 ; this is the end of the number so we print a newline marker
    call printf
    add esp,4
    endFunc

Print_Nodes:
    startFunc
    mov ebx,[ebp+8]                      ; puts the address of the link in ebx
    mov ecx, 0                           ; intialize ecx (we will put the data for print in it)
    mov cl,[ebx+NODE_DATA]                    ; move the data of the link into cl
    mov ebx, dword [ebx+NODE_NEXT_POINTER]            ; advance ebx to the next link
    cmp ebx,0                            ; check if this link points to null 
    je Print_First_Node_Rec                          ; if the next link is null we have reached the end of the list and now we will print it
    
    pushad                               ; if its not the end we backup registers
    push ebx                             ; push the address of the next link 
    call Print_Nodes
    add esp,4
    popad                                ; restore registers

print_a_link:
    push ecx                             ; push ecx which contains the data for printing
    push print_data_format                      ; push the format of printing
    call printf
    add esp,8
    endFunc
    
Print_First_Node_Rec:
    push ecx                                     ; push ecx which contains the data for printing
    push print_data_format_without_zero                        ; push the format of printing without leading zero
    call printf
    add esp,8
    endFunc
	
	
	
;---------------------------------Addition-------------------------------------------------------------------------

	

addFunc:
    startFunc
    CheckToPrintDebug MsgAddFunc
    cmp byte[counter_stack_size] ,1 ; check if there are numbers in the stack for Addition.
    jle errorNotEnoughArgumentFunc
    
    
    mov ebx , 0
    mov ebx , dword[counter_operation]
    inc ebx ; increase 	number of operations
    mov dword[counter_operation] , ebx
    
    mov esi, 0
    mov esi , dword[counter_stack_size]
    dec esi
    mov dword[counter_stack_size], esi
    
    mov edx,0
    mov ebx,0
    mov ebx , [CALC_STACK + esi * 4 ] ; save first argumant
    mov edx , [CALC_STACK + esi * 4 -4] ; save second argumant
    
    Loop_Add_Nodes:
        mov ecx, 0
        mov eax, 0
        mov cl,  [edx + NODE_DATA]
        mov al,  [ebx + NODE_DATA]
        adc al , cl
	daa
        mov [edx+NODE_DATA], al
        pushfd
        cmp dword[ebx + NODE_NEXT_POINTER], 0
        je NODE_EBX_END
        cmp dword[edx + NODE_NEXT_POINTER], 0
        je NODE_EDX_END
        popfd
        mov ebx, [ebx + NODE_NEXT_POINTER]
	mov edx, [edx + NODE_NEXT_POINTER]
        jmp Loop_Add_Nodes
        
    
    
    
    NODE_EDX_END:
        mov esi , [ebx+NODE_NEXT_POINTER]
        mov [edx+NODE_NEXT_POINTER] , esi
        
        
        
    
    
    
    NODE_EBX_END:
        cmp byte[edx+NODE_NEXT_POINTER] , 0
        je END_OF_NODES
        mov edx, [edx + NODE_NEXT_POINTER]
        mov al ,[edx+NODE_DATA]
        popfd
        adc al,0
        daa
        pushfd
        mov[edx+NODE_DATA], al
        jmp NODE_EBX_END
    
    
    
    END_OF_NODES:
        popfd
        jnc End_Addition
        
        push edx
        
        push NODE_SIZE
        call malloc
        add esp,4
        
        pop ebx

        mov dword[eax+NODE_NEXT_POINTER], 0
        mov byte[eax+NODE_DATA], 1
        mov dword[ebx+NODE_NEXT_POINTER] , eax
        
    
    End_Addition:
        endFunc
    




		
;-------------------------------------------------------------------------------------------

errorOverflowFunc:
	errorOverflow
	endFunc

errorNotEnoughArgumentFunc:
	errorNotEnoughArgument
	endFunc

errorExponentFunc:
	errorExponent
	endFunc

errorInputFunc:
	errorInput
	endFunc
;-------------------------------------------------------------------------------------------













