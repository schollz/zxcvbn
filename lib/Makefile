release: aubio audiowaveform
	# build things
	cd aubiogo && go build -v
	cd oscconnect && go build -v
	cd oscnotify && go build -v
	cp -r ~/dust/data/zxcvbn .
	rm -rf zxcvbn/samples
	touch zxcvbn/first
	tar -czvf release.tar.gz zxcvbn aubio aubiogo/aubiogo oscnotify/oscnotify oscconnect/oscconnect audiowaveform
	rm -rf norns
	rm -rf zxcvbn

samples:
	mkdir -p ~/dust/data/zxcvbn
	cd ~/dust/data/zxcvbn && \
		wget https://github.com/schollz/zxcvbn/releases/download/assets/samples.tar.gz && \
		tar -xvzf samples.tar.gz && \
		rm samples.tar.gz

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
