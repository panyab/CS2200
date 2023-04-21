! This program executes pow as a test program using the LC 2200 calling convention
! Check your registers ($v0) and memory to see if it is consistent with this program

        ! vector table
vector0:
        .fill 0x00000000                        ! device ID 0
        .fill 0x00000000                        ! device ID 1
        .fill 0x00000000                        ! ...
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000                        ! device ID 7
        ! end vector table

main:	lea $sp, initsp                         ! initialize the stack pointer
        lw $sp, 0($sp)                          ! finish initialization

        lea $t0, vector0                        ! TODO FIX ME: Install timer interrupt handler into vector table
        lea $t1, timer_handler
        sw $t1, 0($t0)
                                                ! TODO FIX ME: Install distance tracker interrupt handler into vector table
        lea $t1, distance_tracker_handler
        sw $t1, 1($t0)

        lea $t0, minval
        lw  $t0, 0($t0)
        addi $t1, $zero, 65535                  ! store 0000ffff into minval (to make comparisons easier)
        sw  $t1, 0($t0)

        ei                                      ! Enable interrupts

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
EXP:    .fill 8
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

MULT:   add $v0, $zero, $zero                   ! allocate space for old frame pointer
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
        sll $s0, $s0, $t0                       ! n = n << 1                    
        srl $s1, $s1, $t0                       ! m /= 2
        br MULT_WHILE

timer_handler:
        addi $sp, $sp, -1                       ! decrement stack pointer
        sw $k0, 0($sp)                          ! save $k0 
        ei                              
        addi $sp, $sp, -1                       ! save $t0 and $t1 
        sw $t0, 0($sp)
        addi $sp, $sp, -1
        sw $t1, 0($sp)

        lea $t0, ticks                          ! load addr of ticks into $t0
        lw $t1, 0($t0)                          ! $t1 = addr of 0xFFFF
        lw $t0, 0($t1)                          ! $t0 = value at 0xFFFF
        addi $t0, $t0, 1                        ! increment ticks
        sw $t0, 0($t1)                          ! store $t0 at $t1

        lw $t1, 0($sp)                          ! restore $t0 and $t1
        addi $sp, $sp, 1
        lw $t0, 0($sp)
        addi $sp, $sp, 1
        di 
        lw $k0, 0($sp)                          ! restore $k0
        addi $sp, $sp, 1
        reti

distance_tracker_handler:
        addi $sp, $sp, -1                       ! decrement stack pointer
        sw $k0, 0($sp)                          ! save $k0 
        ei                              
        addi $sp, $sp, -1                       ! save $t0 and $t1 and $2
        sw $t0, 0($sp)
        addi $sp, $sp, -1
        sw $t1, 0($sp)
        addi $sp, $sp, -1
        sw $t2, 0($sp)

        in $t0, 0x1                             ! $t0 = value from dist tracker
        lea $t1, minval                         ! $t2 = addr of minval 
        lw $t1, 0($t1)                          ! $t2 = 0xFFFB
        lw $t2, 0($t1)
        skpgt $t2, $t0
        br max
        skpeq $t0, $t2
        sw $t0, 0($t1)

max:    
        lea $t1, maxval                         ! $t1 = address of maxval 
        lw $t1, 0($t1)                          ! $t1 = 0xFFFC
        lw $t2, 0($t1)
        skpgt $t0, $t2
        br shift 
        sw $t0, 0($t1)

shift:
        addi $t0, $zero, 1                      ! $t0 = 1
        lea $t1, maxval
        lw $t1, 0($t1)
        lw $t1, 0($t1)                          ! $t1 = maxval
        lea $t2, lshift
        lw $t2, 0($t2)                          ! t2 = 0xFFFE
        sll $t1, $t1, $t0                       ! $t1 = maxval ($t1) left shifted by 1
        sw $t1, 0($t2)
                  
        addi $t0, $zero, 1                      ! $t0 = 1
        lea $t1, minval
        lw $t1, 0($t1)
        lw $t1, 0($t1)  
        lea $t2, rshift
        lw $t2, 0($t2)         
        srl $t1, $t1, $t0                       ! $t2 = minval ($t2) right shifted by 1
        sw $t1, 0($t2)                          ! store $t2 at 0xFFFE 

        lw $t2, 0($sp)                          ! restore $t0, $t1, $t2
        addi $sp, $sp, 1
        lw $t1, 0($sp)
        addi $sp, $sp, 1
        lw $t0, 0($sp)
        addi $sp, $sp, 1
        di 
        lw $k0, 0($sp)                          ! restore $k0
        addi $sp, $sp, 1
        reti



initsp: .fill 0xA000
ticks:  .fill 0xFFFF
lshift: .fill 0xFFFE
rshift: .fill 0xFFFD
maxval: .fill 0xFFFC
minval: .fill 0xFFFB
