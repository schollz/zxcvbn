release: aubio audiowaveform FVerb
	# build things
	cd aubiogo && go build -v
	cd oscconnect && go build -v
	cd oscnotify && go build -v
	tar -czvf release.tar.gz FVerb aubio aubiogo/aubiogo oscnotify/oscnotify oscconnect/oscconnect audiowaveform
	rm -rf aubio
	rm -rf norns

FVerb:
	faust2sc.py fverb.dsp -o FVerb
	
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
