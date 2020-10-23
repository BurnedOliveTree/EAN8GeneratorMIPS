# Ksawery Chodyniecki
# zamiania kodu EAN8 decymalnego na binarny - generacja obrazków

.eqv	headeraddr  0
.eqv	imgaddr     4
.eqv	filesize    8
.eqv	imgwidth   12
.eqv	imgheight  16
.eqv	rowsize    20

.eqv	bytesno 32830
	
.data
	imgdsc:	.word 0
		.word 0
		.word 0
		.word 0
		.word 0
		.word 0

	img:	.space	bytesno
	ifname:	.asciiz "256x80.bmp"
	img2:	.space	bytesno
	ofname:	.asciiz "EAN8.bmp"
	data3:	.space	80
	cypher: .asciiz	"101011000101111010010011010001101010101010000101010110010100100110100000"   # EAN8 + 00000


.text
	main:
		# print mamma mia
	open_r:
		la	$a0, ifname
		li	$a1, 0			# read-only
		li	$a2, 0
		li	$v0, 13
		syscall
		bltz	$v0, exit		# exits if failed to load a file
	read:
		move	$a0, $v0
		la	$a1, img
		li	$a2, bytesno
		li	$v0, 14
		syscall
		move	$t0, $v0		# zachowaj rozmiar pliku
	close1:
		li	$v0, 16
		syscall
	save_info:
		la	$a0, imgdsc
		sw	$a1, filesize($a0)
		sw	$v0, headeraddr($a0)
		lhu	$t0, 10($a1)		# przesuniecie obrazu wzg poczatku pliku
		addu	$t1, $a1, $t0
		sw	$t1, imgaddr($a0)	# adres obrazu
	
		lhu	$t0, 18($a1)		# szerokosc obrazu w pixelach
		sw	$t0, imgwidth($a0)
		lhu	$t0, 22($a1)		# wysokosc obrazu w pixelach
		sw	$t0, imgheight($a0)


	set_rowsize:
		lw	$t0, imgwidth($a0)	# szerokosc w pixelach
		lw	$t4, imgheight($a0)	# szerokosc w pixelach
		# liczenie logarytmu - przez prostote tej czesci program jest w stanie robic jedynie obrazki o szerokosci bedacej wielokrotnoscia 2
		la	$t1, ($t0)
		li	$t9, 0
	log:
		addiu	$t9, $t9, 1
		srl	$t1, $t1, 1
		bgt	$t1, 1, log
		# szerokość jednego "modułu" = szerokosc / 80
		div	$t7, $t0, 5		# / 5
		srl	$t7, $t7, 4		# >> 4
		# ((2 * szerokosc - 1) >> log(szerokosc)) << (log(szerokosc) - 3)
		sll	$t0, $t0, 1		# *2
		subiu	$t0, $t0, 1		# -1
		srlv	$t0, $t0, $t9		# >> log(szerokosc)
		subiu	$t9, $t9, 3		# log(szerokosc) - 3
		sllv	$t0, $t0, $t9		# << (log(szerokosc) - 3)
		sw	$t0, rowsize($a0)
	paint:
		la	$a0, imgdsc
		li	$a1, 0			# x = 0
		la	$t6, cypher
		li	$t8, 0			# loop counter
		mul	$t9, $t7, 80		# max width
	paint_code:
		li	$a2, 0			# y = 0
		lbu	$t5, ($t6)
		beq	$t5, '0', paint_check	# pomija jeśli jest '0'
	paint_line:
		jal	set_pixel
		addiu	$a2, $a2, 1
		blt	$a2, $t4, paint_line	# 32 - heigth of the file
	paint_check:
		addiu	$t8, $t8, 1
		addiu	$a1, $a1, 1
		blt	$t8, $t7, paint_code
		li	$t8, 0
		addiu	$t6, $t6, 1
		blt	$a1, $t9, paint_code	# 32 - width of the file
	open_w:
		la	$a0, ofname
		li	$a1, 1			# write-only
		li	$a2, 0
		li	$v0, 13
		syscall
		bltz	$v0, exit		# exits if failed to load a file
	write:
		move	$a0, $v0
		la	$a1, img
		li	$a2, bytesno
		li	$v0, 15
		syscall
	close2:
		li	$v0, 16
		syscall
	exit:
		li	$v0, 10
		syscall



	set_pixel:
		# adres wiersza, w ktorym jest pixel
		lw	$t0, rowsize($a0)
		mul	$t0, $t0, $a2		# wybranie dobrego rzedu
		srl	$t1, $a1, 3		# przesuniecie w poziomie o pelne bajty
		add	$t0, $t0, $t1		# offset bajtu wzgledem poczatku obrazu
		lw	$t1, imgaddr($a0)
		add	$t0, $t0, $t1		# adres bajtu zawiejacego pixel

		andi	$t1, $a1, 0x07		# indeks pixela w bajcie
		li	$t2, 0x80		# maska bitowa najstarszego bitu
		srlv	$t2, $t2, $t1
		lb	$t1, 0($t0)		# 8 pixeli obrazu

		nor	$t2, $t2, $t2		# Zanegowanie maski
		and	$t1, $t1, $t2		# Ustaw czarny - Suma maski i 8 bitow (na biały OR)
		sb	$t1, 0($t0)
		jr	$ra

	
	set_mask:
		li	$t2, 0
		li	$t7, 0			# loop counter
	mask_loop:
		lbu	$t5, ($t6)
		subiu	$t5, $t5, '0'
		addu	$t2, $t2, $t5
		sll	$t2, $t2, 1
		addiu	$t6, $t6, 1
		addiu	$t7, $t7, 1
		blt	$t7, 8, mask_loop		