astyle --convert-tabs --break-blocks *.C *.c *.cpp *.h
rm *.orig
perltidy -bl -b -bext='.tidybak' *.pl
rm *.tidybak
