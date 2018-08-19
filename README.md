GDS2
====

This Ruby port of the GDS2 Perl module is mostly untested and incomplete.

The API will change and I plan to heavy modify the interface.

# Todo list:
+ [x] : rough port of Perl codebase to Ruby
+ [ ] : port unit-tests and add additional tests (rspec)
+ [ ] : get gds2 write/read working with known testcases
+ [ ] : refactor code to remove duplication
+ [ ] : refactor code to reduce all of the large methods
+ [ ] : performance improvements

//nanobowers

Original Perl readme:

	This is GDS2, a module for creating programs to read,
	write, and manipulate GDS2 (GDSII) stream files.


	GDS2 should be able to handle any size gdsii file but
	I would consider it too slow for anything larger
	than a few megabytes in size. If your files are are
	closer to the gigabyte range please check out my
	gdt programs at: http://sourceforge.net/projects/gds2/
	which you can use to open and process GDS2 files
	as a pipe from Perl.

	2014: after 15 years I'm opening up this module for anyone
	to help take over in PAUSE (https://pause.perl.org/pause/).
	Peace,
	Ken Schumack

	perl -le '$_=q(Zpbhgnpe@pvnt.uxa);$_=~tr/n-sa-gt-zh-mZ/a-zS/;print;'

