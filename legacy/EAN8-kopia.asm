.eqv	headeraddr  0
.eqv	imgaddr     4
.eqv	filesize    8
.eqv	imgwidth   12
.eqv	imgheight  16
.eqv	rowsize    20
	
	.data
imgdescriptor:	.word 0
		.word 0
		.word 0
		.word 0
		.word 0
		.word 0

img:		.space	256
fname:		.asciiz "white32x32.bmp"
outfname:	.asciiz "outfile.bmp"

	.text
main:
	la $a0, fname
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	
	bltz $v0, main_exit
	
	move $a0, $v0
	
	la $a1, img
	li $a2, 256
	li $v0, 14
	syscall
	
	move $t0, $v0
	
	li $v0, 16
	syscall
	
	la $a0, imgdescriptor
	sw $a1, filesize($a0)
	sw $v0, headeraddr($a0)
	
	lhu $t0, 10($a1)	# przesuniecie obrazu wzg poczatku pliku
	addu $t1, $a1, $t0	# adres obrazu
	sw $t1, imgaddr($a0)	# imgdescriptor->imgaddr = $t1
	
	lhu $t0, 18($a1)	# szerokosc obrazu w pixelach
	sw $t0, imgwidth($a0)
	lhu $t0, 22($a1)	# wysokosc obrazu w pixelach
	sw $t0, imgwidth($a0)

	# ((bajty_obrazu + 3) / 4) * 4
	# ((bajty_obrazu + 3) >> 2) << 2
	# (bajty_obrazu + 3) & 0xFFFFFFFC
	# ((bity_obrazu + 31) / 32) * 4
	# ((bity_obrazu + 31) >> 5) << 2
	
	lw $t0, imgwidth($a0)	# szerokosc w pixelach
	addiu $t0, $t0, 31
	srl $t0, $t0, 5
	sll $t0, $t0, 2
	sw $t0, rowsize($a0)
	
	la $a0, imgdescriptor
	li $a1, 3 # x = 3
	li $a2, 5 # y = 4
	li $a3, 0 # kolor pixela
	jal set_pixel
	
	la $a0, outfname
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $a0, $v0
	la $a1, img
	li $a2, 190
	li $v0, 15
	syscall
	
	li $v0, 16
	syscall
	
main_exit:
	li $v0, 10
	syscall

set_pixel:
	# adres wiersza, w ktorym jest pixel
	lw $t0, rowsize($a0)
	mul $t0, $t0, $a2
	srl $t1, $a1, 3		# przesuniecie w poziomie o pelne bajty
	add $t0, $t0, $t1	# offset bajtu wzgl�dem poczatku obrazu
	
	lw $t1, imgaddr($a0)
	add $t0, $t0, $t1	# adres bajtu zawiejacego pixel
	
	andi $t1, $a1, 0x07	# indeks pixela w bajcie
	li $t2, 0x80		# maska bitowa najstarszego bitu
	srlv $t2, $t2, $t1
	lb $t1, 0($t0)		# 8 pixeli obrazu
	
	beqz $a3, set_black
	or $t1, $t1, $t2
	sb $t1, 0($t0)
	jr $ra
set_black:
	not $t2, $t2		# Zanegowanie maski
	and $t1, $t1, $t2	# Suma maski i 8 bitow
	sb $t1, 0($t0)
	jr $ra
