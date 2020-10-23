# EAN8 Barcode Generator in Assembly MIPS

With this program, you can convert a string of numbers representing EAN8 into a graphical barcode, saved as a bitmap.

Before running, you will probably need to change the path to template blank images and output in line 36 and 38. Line 36 is also where you can change the size of the image, that will be generated.

To change the EAN8 code that you want to be generated, change the value in parentheses in line 21: "decim:	.asciiz "12345670"".

EAN8.bmp has been included in this repository as an example.
