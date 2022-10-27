serve:
	air

build:
	go build -v -x
	./builder

commit:
	git add ../build/static/*
	git add content/*
	git commit -a

install:
	go install -v github.com/cosmtrek/air@latest