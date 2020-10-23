# Ksawery Chodyniecki
# zamiania kodu EAN8 decymalnego na binarny - generacja stringow

.data
	data1:	.space	8
	decim:	.asciiz "53245324"
	data2:	.space	75
	binar:	.asciiz ""
	data3:	.space	80
	cypher: .asciiz	"0001101001100100100110111101010001101100010101111011101101101110001011"
			#0	1      2      3      4      5      6      7      8      9
	
.text
	main:
		la	$t0, binar
		la	$t1, decim
		li	$t7, '0'
		li	$t8, '1'
		jal	header
		jal	encode
		jal	encode
		jal	encode
		jal	encode
		jal	middle
		jal	encodeN
		jal	encodeN
		jal	encodeN
		jal	encodeN
		jal	header
	print:
		la	$a0, binar
		li	$v0, 4
		syscall
	exit:
		li	$v0, 10
		syscall



	encode:
		lbu	$t2, ($t1)
		subiu	$t2, $t2, '0'
		mul	$t2, $t2, 7
		la	$t3, cypher	# wczytanie 
		addu	$t3, $t3, $t2	# przesuniecie adresu cypher o 8 * liczba w decim
		li	$t2, 0		# loop counter
	loop7:
		lbu	$t4, ($t3)
		sb	$t4, ($t0)
		addiu	$t3, $t3, 1
		addiu	$t0, $t0, 1
		addiu	$t2, $t2, 1
		blt	$t2, 7, loop7
		addiu	$t1, $t1, 1	# przejscie na nastepny znak (decim)
		jr	$ra



	encodeN:
		lbu	$t2, ($t1)
		subiu	$t2, $t2, '0'
		sll	$t2, $t2, 3
		la	$t3, cypher	# wczytanie 
		addu	$t3, $t3, $t2	# przesuniecie adresu cypher o 8 * liczba w decim
		li	$t2, 0		# loop counter
	loop7N:
		lbu	$t4, ($t3)
		subiu	$t4, $t4, '0'	# negowanie
		nor	$t4, $t4, $t4	# negowanie
		addiu	$t4, $t4, '2'	# negowanie
		sb	$t4, ($t0)
		addiu	$t3, $t3, 1
		addiu	$t0, $t0, 1
		addiu	$t2, $t2, 1
		blt	$t2, 7, loop7N
		addiu	$t1, $t1, 1	# przejscie na nastepny znak (decim)
		jr	$ra


	header:
		sb	$t8, ($t0)
		addiu	$t0, $t0, 1
		sb	$t7, ($t0)
		addiu	$t0, $t0, 1
		sb	$t8, ($t0)
		addiu	$t0, $t0, 1
		jr	$ra
	middle:
		sb	$t7, ($t0)
		addiu	$t0, $t0, 1
		sb	$t8, ($t0)
		addiu	$t0, $t0, 1
		sb	$t7, ($t0)
		addiu	$t0, $t0, 1
		sb	$t8, ($t0)
		addiu	$t0, $t0, 1
		sb	$t7, ($t0)
		addiu	$t0, $t0, 1
		jr	$ra
