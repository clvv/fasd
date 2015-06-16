PREFIX?= /usr/local
BINDIR?= ${PREFIX}/bin
MANDIR?= ${PREFIX}/share/man
INSTALL?= install
INSTALLDIR= ${INSTALL} -d
INSTALLBIN= ${INSTALL} -m 755
INSTALLMAN= ${INSTALL} -m 644

all: fad.1

uninstall:
	rm -f ${DESTDIR}${BINDIR}/fad
	rm -f ${DESTDIR}${MANDIR}/man1/fad.1

install:
	${INSTALLDIR} ${DESTDIR}${BINDIR}
	${INSTALLBIN} fad ${DESTDIR}${BINDIR}
	${INSTALLDIR} ${DESTDIR}${MANDIR}/man1
	${INSTALLMAN} fad.1 ${DESTDIR}${MANDIR}/man1

man: fad.1

fad.1: fad.1.md
	pandoc -s -w man fad.1.md -o fad.1

.PHONY: all install uninstall man

