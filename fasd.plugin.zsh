ULB=/usr/local/bin
[[ ! -s ${ULB}/fasd ]] \
	&& echo sudo powers needed to install fasd to ${ULB} \
	&& sudo make install -C ${0:a:h}
