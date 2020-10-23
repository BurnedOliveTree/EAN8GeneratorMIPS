# Ksawery Chodyniecki
# zamiania kodu EAN8 decymalnego na binarny - generacja obrazków

.eqv	headeraddr  0
.eqv	imgaddr     4
.eqv	filesize    8
.eqv	imgwidth   12
.eqv	imgheight  16
.eqv	rowsize    20
	
.data
	imgdsc:	.word 0
		.word 0
		.word 0
		.word 0
		.word 0
		.word 0

	img:	.space	256
	ifname:	.asciiz "white32x32.bmp"
	img2:	.space	256
	ofname:	.asciiz "outfile.bmp"
	data3:	.space	75
	cypher: .asciiz	"1010110001011110100100110100011010101010100001010101100101001001101"


.text
	main:
		# print mamma mia
	open_r:
		la	$a0, ifname
		li	$a1, 0		# read-only
		li	$a2, 0
		li	$v0, 13
		syscall
		bltz	$v0, exit	# exits if failed to load a file
	read:
		move	$a0, $v0
		la	$a1, img
		li	$a2, 190
		li	$v0, 14
		syscall
		move	$t0, $v0	# zachowaj rozmiar pliku
	closer:
		li	$v0, 16
		syscall
	save_info:
		la	$a0, imgdsc
		sw	$a1, filesize($a0)
		sw	$v0, headeraddr($a0)
	
		lhu	$t0, 10($a1)	# przesuniecie obrazu wzg poczatku pliku
		addu	$t1, $a1, $t0	# adres obrazu
		sw	$t1, imgaddr($a0)	# imgdescriptor->imgaddr = $t1
	
		lhu	$t0, 18($a1)	# szerokosc obrazu w pixelach
		sw	$t0, imgwidth($a0)
		lhu	$t0, 22($a1)	# wysokosc obrazu w pixelach
		sw	$t0, imgheight($a0)
		
		lw	$t0, imgwidth($a0)	# szerokosc w pixelach
		addiu	$t0, $t0, 31	# ((bity_obrazu + 31) >> 5) << 2
		srl	$t0, $t0, 5		# ((bity_obrazu + 31) >> 5) << 2
		sll	$t0, $t0, 2		# ((bity_obrazu + 31) >> 5) << 2
		sw	$t0, rowsize($a0)
	paint:
		la	$a0, imgdsc
		li	$a1, 0		# x = 0
		# li $a2, 4		# y = 4
		la	$t6, cypher
		li	$a3, 0		# kolor pixela
	paint_code:
		la	$a2, 0
		lbu	$t5, ($t6)
		beq	$t5, '0', paint_check	# co tu jest
	paint_line:
		jal	set_pixel
		addiu	$a2, $a2, 1
		blt	$a2, 32, paint_line
	paint_check:
		addiu	$t6, $t6, 1
		addiu	$a1, $a1, 1
		blt	$a1, 32, paint_code
	open_w:
		la	$a0, ofname
		li	$a1, 1		# write-only
		li	$a2, 0
		li	$v0, 13
		syscall
		bltz	$v0, exit	# exits if failed to load a file
	write:
		move	$a0, $v0
		la	$a1, img
		li	$a2, 190
		li	$v0, 15
		syscall
	close:
		li	$v0, 16
		syscall
	exit:
		li	$v0, 10
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
		
