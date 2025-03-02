prepare:
	cp .envrc.tpl .envrc

install: render link

render:
	bin/render.sh

link:
	bin/link.sh
