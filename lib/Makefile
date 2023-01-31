release: build
	tar -czvf release.tar.gz aubiogo/aubiogo oscnotify/oscnotify oscconnect/oscconnect acrostic/acrostic osccpu/osccpu

build:
	# build things
	cd aubiogo && go build -v
	cd oscconnect && go build -v
	cd oscnotify && go build -v
	cd osccpu && go build -v
	cd acrostic && go build -v 

audiowaveform:
	git clone https://github.com/bbc/audiowaveform.git a1 && \
		mkdir -p a1/build && \
		cd a1/build && \
		cmake -D ENABLE_TESTS=0 -D BUILD_STATIC=1 .. && make && \
		mv audiowaveform ../../
	rm -rf a1

aubio:
	git clone https://git.aubio.org/aubio/aubio && cd aubio && \
		make

install:
	tar -xvzf release.tar.gz
	cd aubio && sudo ./waf install --destdir=/
	sudo ldconfig

clean:
	rm -rf release.tar.gz
	rm -rf aubio
	rm -rf a1

cjson:
	echo "note: requires liblua5.3-dev"
	rm -rf lua-cjson
	git clone --depth 1 https://github.com/mpx/lua-cjson.git
	cd lua-cjson && cc -c -O3 -Wall -pedantic -DNDEBUG  -I/usr/include/lua5.3 -fpic -o lua_cjson.o lua_cjson.c
	cd lua-cjson && cc -c -O3 -Wall -pedantic -DNDEBUG  -I/usr/include/lua5.3 -fpic -o strbuf.o strbuf.c
	cd lua-cjson && cc -c -O3 -Wall -pedantic -DNDEBUG  -I/usr/include/lua5.3 -fpic -o fpconv.o fpconv.c
	cd lua-cjson && cc  -shared -o cjson.so lua_cjson.o strbuf.o fpconv.o
	cp lua-cjson/cjson.so .

all: build cjson

