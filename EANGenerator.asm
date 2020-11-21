# Ksawery Chodyniecki
# zamiana 8-cyfrowego decymalnego kodu EAN8 na zakodowany "kod paskowy"
#
# najmniejszy działający plik: 67x1
# najmniejszy działający plik wyższy niż 1 piksel: 72x2
# największy sprawdzony plik: 2048x32, ograniczone jest to za pomocą bytesno

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
	ifname:	.asciiz "EAN8/templates/72x32.bmp"
	img2:	.space	bytesno
	ofname:	.asciiz "EAN8/EAN8.bmp"

.text
	main:
		jal	decode	# tworzenie kodu
		jal	open_r	# otwieranie pliku i zapisywanie informacji
		jal	paint	# malowanie kodu
		j	open_w	# zapisywanie i zamykanie pliku

# ----------------------------------------------
#		Tworzenie kodu
# ----------------------------------------------
	# zakodowuje cały ciąg 8 znaków plus nagłówki
	decode:
		la	$t9, ($ra)

		la	$t0, binar
		la	$t1, decim
		li	$a0, '1'	# pierwszy znak
		li	$a1, 3		# ilość znaków
		li	$a2, 1		# 1 jeśli pulsuje, 0 jeśli stałe
		jal	wave_loop
		li	$a0, 0		# 0 dla A, 1 dla C (typy kodu EAN8)
		li	$a1, 4		# licznik pętli
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

		jr	$t9

	# $a0: 0 dla A, 1 dla C (typy kodu EAN8); $a1: ilość znaków
	encode:
		lbu	$t2, ($t1)
		subiu	$t2, $t2, '0'
		la	$t3, ($t2)
		sll	$t2, $t2, 3
		subu	$t2, $t2, $t3
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
	wave_loop_zero:
		addiu	$a0, $a0, 1
		j	wave_loop_end
	wave_loop_one:
		subiu	$a0, $a0, 1
	wave_loop_end:
		bgtz	$a1, wave_loop
		jr	$ra

# ----------------------------------------------
#		Malowanie kodu
# ----------------------------------------------
	paint:
		la	$t9, ($ra)

		li	$a1, 0			# x = 0
		li	$a3, 1			# 1 = czarny, 0 = biały
		la	$s3, binar
		li	$t8, 0			# licznik pętli
	paint_code:
		li	$a2, 0			# y = 0
		lbu	$t5, ($s3)
		beq	$t5, '0', paint_check	# pomija jeśli jest '0'
		jal	set_mask
		addiu	$a2, $a2, 1
	paint_line:
		jal	set_pixel
		addiu	$a2, $a2, 1
		blt	$a2, $s2, paint_line	# sprawdza czy to nie jest wysokość pliku juz
	paint_check:
		addiu	$t8, $t8, 1
		addiu	$a1, $a1, 1
		blt	$t8, $t7, paint_code
		li	$t8, 0
		addiu	$s3, $s3, 1
		blt	$a1, $s1, paint_code	# sprawdza czy to nie jest max. szerokosc kodu juz

		jr	$t9

	# $a1: x, $a2: y, $a3: 0 dla białego, 1 dla czarnego
	set_mask:
		# adres wiersza
		lw	$t3, rowsize($s0)
		mul	$t0, $t3, $a2		# wybranie dobrego rzedu
		srl	$t1, $a1, 3		# przesuniecie w poziomie o pelne bajty
		add	$t0, $t0, $t1		# offset bajtu wzgledem poczatku obrazu
		lw	$t1, imgaddr($s0)
		add	$t0, $t0, $t1		# adres bajtu zawiejacego pixel
		# ustawienie maski
		andi	$t1, $a1, 0x07		# indeks pixela w bajcie
		li	$t2, 0x80		# maska bitowa najstarszego bitu
		srlv	$t2, $t2, $t1
		lb	$t1, 0($t0)		# 8 pixeli obrazu
		beqz	$a3, set_mask_white
	set_mask_black:
		nor	$t2, $t2, $t2		# Zanegowanie maski
		and	$t1, $t1, $t2		# Ustaw czarny - Suma maski i 8 bitow
		j	set_pixel
	set_mask_white:
		or	$t1, $t1, $t2		# Ustaw biały
	set_pixel:
		sb	$t1, 0($t0)
		addu	$t0, $t0, $t3
		jr	$ra

# ----------------------------------------------
#	Otwieranie pliku i zapisywanie informacji
# ----------------------------------------------
	open_r:
		la	$a0, ifname
		li	$a1, 0			# wersja tylko do odczytu
		li	$a2, 0
		li	$v0, 13
		syscall
		bltz	$v0, exit		# wychodzi jeśli nie udało mu się otworzyć pliku
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
		lhu	$t0, 10($a1)		# przesunięcie obrazu wzg. poczętku pliku
		addu	$t1, $a1, $t0
		sw	$t1, imgaddr($s0)	# adres obrazu
	
		lhu	$t0, 18($a1)		# szerokość obrazu w pixelach
		sw	$t0, imgwidth($s0)
		lhu	$t0, 22($a1)		# wysokość obrazu w pixelach
		sw	$t0, imgheight($s0)
	set_rowsize:
		lw	$t0, imgwidth($s0)	# szerokość w pixelach
		lw	$s2, imgheight($s0)	# wysokość w pixelach
		la	$t1, ($t0)
		li	$s1, 0
	log:
		addiu	$s1, $s1, 1
		srl	$t1, $t1, 1
		bgt	$t1, 1, log
		# szerokość jednego "modułu"
		div	$t7, $t0, codelen
		# rowsize = (szer / 8) + 8 - (szer / 8) % 8
		srl	$t0, $t0, 3
		srl	$t6, $t0, 2
		sll	$t6, $t6, 2
		subu	$t6, $t0, $t6
		beqz	$t6, jump_add_4
		addiu	$t0, $t0, 4
	jump_add_4:
		subu	$t0, $t0, $t6
		sw	$t0, rowsize($s0)
		mul	$s1, $t7, codelen	# szerokość całego kodu EAN8
		
		jr	$ra

# ----------------------------------------------
#	Zapisywanie i zamykanie pliku
# ----------------------------------------------
	open_w:
		la	$a0, ofname
		li	$a1, 1			# tylko do zapisu
		li	$a2, 0
		li	$v0, 13
		syscall
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
