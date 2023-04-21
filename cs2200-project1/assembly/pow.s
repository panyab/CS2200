! Fall 2022 Revisions by Andrej Vrtanoski

! This program executes pow as a test program using the LC 2200 calling convention
! Check your registers ($v0) and memory to see if it is consistent with this program

main:	lea $sp, initsp                         ! initialize the stack pointer
        lw $sp, 0($sp)                          ! finish initialization

        lea $a0, BASE                           ! load base for pow
        lw $a0, 0($a0)
        lea $a1, EXP                            ! load power for pow
        lw $a1, 0($a1)
        lea $at, POW                            ! load address of pow
        jalr $ra, $at                           ! run pow
        lea $a0, ANS                            ! load base for pow
        sw $v0, 0($a0)

        halt                                    ! stop the program here
        addi $v0, $zero, -1                     ! load a bad value on failure to halt

BASE:   .fill 17
EXP:    .fill 3
ANS:	.fill 0                                 ! should come out to 256 (BASE^EXP)

POW:    addi $sp, $sp, -1                       ! allocate space for old frame pointer
        sw $fp, 0($sp)

        addi $fp, $sp, 0                        ! set new frame pointer

        skpgt $a1, $zero                        ! check if $a1 is zero
        br RET1                                 ! if the exponent is 0, return 1
        skpgt $a0, $zero                        ! if the base is 0, return 0
        br RET0                                 

        addi $a1, $a1, -1                       ! decrement the power

        lea $at, POW                            ! load the address of POW
        addi $sp, $sp, -2                       ! push 2 slots onto the stack
        sw $ra, -1($fp)                         ! save RA to stack
        sw $a0, -2($fp)                         ! save arg 0 to stack
        jalr $ra, $at                           ! recursively call POW
        add $a1, $v0, $zero                     ! store return value in arg 1
        lw $a0, -2($fp)                         ! load the base into arg 0
        lea $at, MULT                           ! load the address of MULT
        jalr $ra, $at                           ! multiply arg 0 (base) and arg 1 (running product)
        lw $ra, -1($fp)                         ! load RA from the stack
        addi $sp, $sp, 2

        br FIN                                  ! unconditional branch to FIN

RET1:   add $v0, $zero, $zero                   ! return a value of 0
	addi $v0, $v0, 1                        ! increment and return 1
        skpgt $v0, $zero                        ! unconditional branch to FIN

RET0:   add $v0, $zero, $zero                   ! return a value of 0

FIN:	lw $fp, 0($fp)                          ! restore old frame pointer
        addi $sp, $sp, 1                        ! pop off the stack
        jalr $zero, $ra

MULT:   add $v0, $zero, $zero                       ! allocate space for old frame pointer
        addi $t0, $zero, 0                      ! sentinel = 0
        addi $s0, $a0, 0
        addi $s1, $a1, 0
        
MULT_WHILE:  
        skpgt $s1, $zero                        ! check if a0 is zero and return
        jalr $zero, $ra

        addi $t0, $zero, 1                        
        nand $t0, $t0, $s1
        nand $t0, $t0, $t0                      ! calculate (a1 & 0x01)

MULT_IF: 
        skpeq $t0, $zero                        ! skip if (a1 % 2 != 1)
        add $v0, $v0, $s0                       ! ans += n   
        
        addi $t0, $zero, 1    
        sll $s0, $s0, $t0                       ! n = n << 2                    
        srl $s1, $s1, $t0                       ! m /= 2
        br MULT_WHILE
        
initsp: .fill 0xA000
