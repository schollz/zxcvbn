release: aubio audiowaveform
	cd aubiogo && go build -v
	cd oscconnect && go build -v
	cd oscnotify && go build -v
	tar -czvf release.tar.gz aubio aubiogo/aubiogo oscnotify/oscnotify oscconnect/oscconnect audiowaveform
	rm -rf aubio
	rm -rf audiowaveform


audiowaveform:
	git clone https://github.com/bbc/audiowaveform.git && \
		mkdir -p audiowaveform/build && \
		cd audiowaveform/build && \
		cmake -D ENABLE_TESTS=0 .. && make
aubio:
	git clone https://git.aubio.org/aubio/aubio && cd aubio && \
		make

install:
	tar -xvzf release.tar.gz
	cd audiowaveform/build && sudo make install
	cd aubio && sudo ./waf install --destdir=/
	sudo ldconfig

clean:
	rm -rf aubio
	rm -rf audiowaveform
