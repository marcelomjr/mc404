/* calculo de n-esimo termo da serie de fibonacci
   f_1 = 1, f_2 = 1, f_3 = 2, ...
   input: n, onde o n-esimo termo da serie sera computado, em formato string binaria de 16 digitos
   output: o n-esimo termo da serie, em formato string binaria de 16 digitos
*/

.text

.globl _start
_start:
	@ call read(stdin, n_addr, 16)
	mov r0, #0 @ standard input file descriptor
	ldr r1, =n_addr
	mov r2, #16 @ read 16 bytes (the binary string representing n)
	mov r7, #3 @ syscall number for read
	svc 0x0

	@ debug: print the return value of read
	@ldr r1, =aux_buffer
	@str r0, [r1]
	@mov r0, #1
	@mov r2, #4
	@mov r7, #4
	@svc 0x0

	cmp r0, #16 @ if we didn't read exactly 16 bytes
	bne error_invalidinputlength @ then we don't have the correct input

	@ now parse the binary string into a number
push {r4-r7} @ aux registers (callee saved)
	ldr r4, =n_addr
	mov r5, #0 @ loop counter
	mov r6, #0 @ initialize n to be zero
parseloop:
	cmp r5, #16 @ if we read 16 characters
	beq done_parseloop @ then we're done reading
	ldrb r7, [r4, r5] @ load the value of next bit to be read
	sub r7, #'0' @ convert it to an actual number
	cmp r7, #1 
	bgt error_notbinarystring
	cmp r7, #0
	blt error_notbinarystring @ must be '0' or '1'
	mov r6, r6, lsl #1 @ we have another bit to place in n
	add r6, r6, r7 @ add the newly read bit to the number n
	add r5, #1 @ counter++
	b parseloop
done_parseloop:

	cmp r6, #24 @ if n > 24, fib(n) won't fit in 16 bits
	bgt error_outputdoesntfit

	@ now calculate fib(n)
	mov r2, #1 @ prev = 1
	mov r3, #1 @ curr = 1
	mov r5, #3 @ loop counter (we calculated fib(1) and fib(2) already)
fib_loop:
	cmp r5, r6 @ if loop counter > n
	bgt done_fib_loop @ then we calculated the correct number
	mov r1, r3 @ tmp = curr
	add r3, r2, r3 @ curr = curr + prev
	mov r2, r1 @ prev = tmp (used to curr)
	add r5, #1 @ loop counter ++
	b fib_loop
done_fib_loop:
	
	@ r3 has fib(n). place the result in a buffer in binary string form
	ldr r1, =fib_n_addr @ we will store the result here
	mov r5, #15 @ loop counter (we will be printing the binary string in big endian form)
output_print_loop:
	cmp r5, #0 @ if loop counter < 0, we are done
	blt done_output_print_loop
	and r4, r3, #1 @ take the lsb
	add r4, #'0' @ convert it to ascii
	strb r4, [r1, r5] @ and place it into the output buffer
	mov r3, r3, lsr #1 @ look at next bit
	sub r5, #1 @ loop counter --
	b output_print_loop
done_output_print_loop:
	pop {r4-r7} @ restore aux registers 
	
	@ now print the result
	@ call write(stdout, fib_n_addr, 16)
	mov r0, #1 @ 1 is the file descriptor for stdout
	ldr r1, =fib_n_addr
	mov r2, #16 @ size of the output buffer
	mov r7, #4 @ syscall number for write
	svc 0x0
	
	@ now call exit(0)
	mov r0, #0 @ exit success
	mov r7, #1 @ syscall number for exit
	svc 0x0
@ goodbye

@ error exits:
error_invalidinputlength:
	ldr r1, =error_invalidinputlength_msg
	mov r2, #(error_invalidinputlength_msgend - error_invalidinputlength_msg)
	b fatal_error

error_outputdoesntfit:
pop {r4-r7}
	ldr r1, =error_outputdoesntfit_msg
	mov r2, #(error_outputdoesntfit_msgend - error_outputdoesntfit_msg)
	b fatal_error

error_notbinarystring:
pop {r4-r7}
	ldr r1, =error_notbinarystring_msg
	mov r2, #(error_notbinarystring_msgend - error_notbinarystring_msg)
	b fatal_error

fatal_error: @ takes as parameters the pointer to the error message in r1 and its length in r2
	@ call write(stdout, errormsg, length)
	mov r0, #1 @ standard output file descriptor
	@ r1 already set by the caller
	@ r2 already set by the caller
	mov r7, #4 @ syscall number for write
	svc 0x0
	@ call exit(-1)
	mov r0, #-1
	mov r7, #1 @ syscall number for exit
	svc 0x0

.data

.align 4
n_addr: .skip 16
fib_n_addr: .skip 16

error_invalidinputlength_msg: .ascii "error: did not read 16 byte binary string from stdin"
error_invalidinputlength_msgend: .word 0
.align 4
error_notbinarystring_msg: .ascii "error: expected a binary string with (ascii) ones and zeroes"
error_notbinarystring_msgend: .word 0
.align 4
error_outputdoesntfit_msg: .ascii "error: the output only fits in a 16 bit number; fibonacci input must be in the range [0,24]"
error_outputdoesntfit_msgend: .word 0
.align 4
aux_buffer: .word 0


