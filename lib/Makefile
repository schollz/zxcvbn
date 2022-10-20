release: aubio audiowaveform
	# generate a patch for norns
	git clone --depth 1 https://github.com/monome/norns
	sed -i 's/if cmd=="\/remote\/key" then/if cmd=="\/remote\/brd" then keyboard.process(1,n,val) elseif cmd=="\/remote\/key" then/g' norns/lua/core/osc.lua
	sed -i 's/if _menu.keyboardcode/if c=="MINUS" then _menu.penc(3,value*-1) elseif c=="EQUAL" then _menu.penc(3,value) end; if _menu.keyboardcode/g' norns/lua/core/menu.lua
	sed -i 's/if value==1 then/if value>=1 then/g' norns/lua/core/menu.lua
	sed -i 's/elseif _menu.mode then _menu.keycode(c,value)/elseif (c=="F1" or c=="F2" or c=="F3" or c=="F4") and value==1 then _menu.set_mode(true); _menu.keycode(c,value) elseif (c=="F5" and value==1) then _menu.set_mode(not _menu.mode) elseif _menu.mode then _menu.keycode(c,value)/g' norns/lua/core/keyboard.lua
	cd norns && git diff > ../keyboard.patch
	# build things
	cd aubiogo && go build -v
	cd oscconnect && go build -v
	cd oscnotify && go build -v
	tar -czvf release.tar.gz keyboard.patch aubio aubiogo/aubiogo oscnotify/oscnotify oscconnect/oscconnect audiowaveform
	rm -rf aubio
	rm -rf norns
	
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
