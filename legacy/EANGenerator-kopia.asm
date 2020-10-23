# Ksawery Chodyniecki
# zamiania kodu EAN8 decymalnego na binarny - generacja obrazków

.eqv	headeraddr  0
.eqv	imgaddr     4
.eqv	filesize    8
.eqv	imgwidth   12
.eqv	imgheight  16
.eqv	rowsize    20

.eqv	bytesno 32830
.eqv	codelen	67
	
.data
	# text conversion data
	data1:	.space	8
	decim:	.asciiz "12345670"
	data2:	.space	codelen
	binar:	.asciiz ""
	data3:	.space	70
	cypher: .asciiz	"0001101001100100100110111101010001101100010101111011101101101110001011"
			#0	1      2      3      4      5      6      7      8      9

	# image data
	imgdsc:	.word 0
		.word 0
		.word 0
		.word 0
		.word 0
		.word 0

	img:	.space	bytesno
	ifname:	.asciiz "128x128.bmp"
	img2:	.space	bytesno
	ofname:	.asciiz "EAN8.bmp"

.text
	main:
		la	$t0, binar
		la	$t1, decim
		li	$a0, '1'	# first sign
		li	$a1, 3		# no of signs
		li	$a2, 1		# 1 if its changing, 0 if static
		jal	wave_loop
		li	$a0, 0		# 0 for A, 1 for C (types of EAN8 code)
		li	$a1, 4		# loop counter
		jal	encode
		li	$a0, '0'
		li	$a1, 5
		jal	wave_loop
		li	$a0, 1
		li	$a1, 4
		jal	encode
		li	$a0, '1'
		li	$a1, 3
		jal	wave_loop
		# li	$a0, '0'
		# li	$a1, 5
		# li	$a2, 0
		# jal	wave_loop
	print:
		la	$a0, binar
		li	$v0, 4
		syscall
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
		la	$s0, imgdsc
		sw	$a1, filesize($s0)
		sw	$v0, headeraddr($s0)
		lhu	$t0, 10($a1)		# przesuniecie obrazu wzg poczatku pliku
		addu	$t1, $a1, $t0
		sw	$t1, imgaddr($s0)	# adres obrazu
	
		lhu	$t0, 18($a1)		# szerokosc obrazu w pixelach
		sw	$t0, imgwidth($s0)
		lhu	$t0, 22($a1)		# wysokosc obrazu w pixelach
		sw	$t0, imgheight($s0)


	set_rowsize:
		lw	$t0, imgwidth($s0)	# szerokosc w pixelach
		lw	$s2, imgheight($s0)	# wysokosc w pixelach
		# liczenie logarytmu - przez prostote tej czesci program jest w stanie robic jedynie obrazki o szerokosci bedacej wielokrotnoscia 2
		la	$t1, ($t0)
		li	$s1, 0
	log:
		addiu	$s1, $s1, 1
		srl	$t1, $t1, 1
		bgt	$t1, 1, log
		# szerokość jednego "modułu"
		div	$t7, $t0, codelen
		# ((2 * szerokosc - 1) >> log(szerokosc)) << (log(szerokosc) - 3)
		sll	$t0, $t0, 1		# * 2
		subiu	$t0, $t0, 1		# - 1
		srlv	$t0, $t0, $s1		# >> log(szerokosc)
		subiu	$s1, $s1, 3		# log(szerokosc) - 3
		sllv	$t0, $t0, $s1		# << (log(szerokosc) - 3)
		sw	$t0, rowsize($s0)
		
		# j	all_byte
		
	paint:
		li	$a1, 0			# x = 0
		li	$a3, 1			# 1 = black, 0 = zero
		la	$s3, binar
		li	$t8, 0			# loop counter
		mul	$s1, $t7, codelen	# max width
	paint_code:
		li	$a2, 0			# y = 0
		lbu	$t5, ($s3)
		beq	$t5, '0', paint_check	# pomija jeśli jest '0'
	paint_line:
		jal	set_pixel
		addiu	$a2, $a2, 1
		blt	$a2, $s2, paint_line	# 32 - heigth of the file
	paint_check:
		addiu	$t8, $t8, 1
		addiu	$a1, $a1, 1
		blt	$t8, $t7, paint_code
		li	$t8, 0
		addiu	$s3, $s3, 1
		blt	$a1, $s1, paint_code	# 32 - width of the file
	fill_w_white:
		li	$a3, 0
		jal	set_pixel
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

# ----------------------------------------------
#		Malowanie pikseli
# ----------------------------------------------

	set_pixel:
		# adres wiersza, w ktorym jest pixel
		lw	$t0, rowsize($s0)
		mul	$t0, $t0, $a2		# wybranie dobrego rzedu
		srl	$t1, $a1, 3		# przesuniecie w poziomie o pelne bajty
		add	$t0, $t0, $t1		# offset bajtu wzgledem poczatku obrazu
		lw	$t1, imgaddr($s0)
		add	$t0, $t0, $t1		# adres bajtu zawiejacego pixel

		# ustawienie maski
		andi	$t1, $a1, 0x07		# indeks pixela w bajcie
		li	$t2, 0x80		# maska bitowa najstarszego bitu
		srlv	$t2, $t2, $t1
		lb	$t1, 0($t0)		# 8 pixeli obrazu

		beqz	$a3, set_pixel_white
	set_pixel_black:
		nor	$t2, $t2, $t2		# Zanegowanie maski
		and	$t1, $t1, $t2		# Ustaw czarny - Suma maski i 8 bitow
		j	set_pixel_end
	set_pixel_white:
		or	$t1, $t1, $t2		# Ustaw biały
	set_pixel_end:
		sb	$t1, 0($t0)
		jr	$ra



	all_byte:
		li	$a1, 0			# x = 0
		mul	$s1, $t7, codelen	# max width
		la	$s3, binar
	paint_byte:
		# adres wiersza, w ktorym jest pixel
		lw	$t1, imgaddr($s0)
		addu	$t0, $t1, $a1
	create_byte:
		li	$a2, 0			# y = 0
		li	$t1, 0
		li	$t6, 0			# loop counter - ten sam znak
		li	$t9, 0			# loop counter - 8 bitow
	fill_byte:
		lbu	$t5, ($s3)
		subiu	$t5, $t5, '0'
		addu	$t1, $t1, $t5
		sll	$t1, $t1, 1
		addiu	$t6, $t6, 1
		blt	$t6, $t7, fill_byte
		addiu	$s3, $s3, 1
		addiu	$t9, $t9, 1
		blt	$t9, 8, fill_byte
		nor	$t1, $t1, $t1
	set_byte:
		sb	$t1, 0($t0)
		addiu	$a2, $a2, 1
		lw	$t8, rowsize($s0)
		addu	$t0, $t0, $t8
		blt	$a2, $s2, set_byte	# $s2 - heigth of the file
		addiu	$a1, $a1, 1
		blt	$a1, $s1, paint_byte	# $s1 - width of the file
		j	open_w

# ----------------------------------------------
#		Konwertowanie tekstu
# ----------------------------------------------

	# $a0: 0 for A, 1 for C (types of EAN8 code); $a1: amount of signs to repeat
	encode:
		lbu	$t2, ($t1)
		subiu	$t2, $t2, '0'
		mul	$t2, $t2, 7
		la	$t3, cypher	# wczytanie 
		addu	$t3, $t3, $t2	# przesuniecie adresu cypher o 7 * liczba w decim
		li	$t2, 0		# licznik petli
	loop7:
		lbu	$t4, ($t3)
		beq	$a0, 0, not_c_code
		subiu	$t4, $t4, '0'	# negowanie
		nor	$t4, $t4, $t4	# negowanie
		addiu	$t4, $t4, '2'	# negowanie
	not_c_code:
		sb	$t4, ($t0)
		addiu	$t3, $t3, 1
		addiu	$t0, $t0, 1
		addiu	$t2, $t2, 1
		blt	$t2, 7, loop7
		addiu	$t1, $t1, 1	# przejscie na nastepny znak (decim)
		subiu	$a1, $a1, 1
		bgtz	$a1, encode
		jr	$ra

	# $a0: first sign; $a1: amount of signs to repeat; $a2: 1 if its changing (10101...), 0 if static (11111...)
	wave_loop:
		sb	$a0, ($t0)
		addiu	$t0, $t0, 1
		subiu	$a1, $a1, 1
		beqz	$a2, wave_loop_end
		beq	$a0, '1', wave_loop_one
		addiu	$a0, $a0, 1
		j	wave_loop_end
	wave_loop_one:
		subiu	$a0, $a0, 1
	wave_loop_end:
		bgtz	$a1, wave_loop
		jr	$ra
