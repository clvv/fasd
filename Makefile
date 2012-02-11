PREFIX?= /usr/local
BINDIR?= ${PREFIX}/bin
MANDIR?= ${PREFIX}/share/man
INSTALL?= install
INSTALLDIR= ${INSTALL} -d
INSTALLBIN= ${INSTALL} -m 755
INSTALLMAN= ${INSTALL} -m 644

all: fasd.1

uninstall:
	rm -f ${DESTDIR}${BINDIR}/fasd
	rm -f ${DESTDIR}${MANDIR}/man1/fasd.1

install:
	${INSTALLDIR} ${DESTDIR}${BINDIR}
	${INSTALLBIN} fasd ${DESTDIR}${BINDIR}
	${INSTALLDIR} ${DESTDIR}${MANDIR}/man1
	${INSTALLMAN} fasd.1 ${DESTDIR}${MANDIR}/man1

man: fasd.1

fasd.1: fasd.1.md
	pandoc -s -w man fasd.1.md -o fasd.1

.PHONY: all install uninstall man

