package main

import (
	"flag"
	"fmt"
	"time"

	"github.com/bep/debounce"
	"github.com/fsnotify/fsnotify"
	"github.com/hypebeast/go-osc/osc"
	log "github.com/schollz/logger"
)

var flagRecvHost, flagRecvAddress, flagHost, flagAddress string
var flagPort int

func init() {
	flag.StringVar(&flagHost, "host", "localhost", "osc host")
	flag.IntVar(&flagPort, "port", 10111, "port to use")
	flag.StringVar(&flagAddress, "addr", "/oscnotify", "osc address")
}

func main() {
	// Create new watcher.
	log.SetLevel("info")
	log.Info("oscnotify started")
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Error(err)
		return
	}
	defer watcher.Close()

	f := func() {
		log.Debugf("changed file")
		client := osc.NewClient(flagHost, flagPort)
		msg := osc.NewMessage(flagAddress)
		msg.Append(int32(1))
		err = client.Send(msg)
		if err != nil {
			log.Error(err)
		}
	}

	debounced := debounce.New(100 * time.Millisecond)

	// Start listening for events.
	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				log.Debugf("event: %s", event)
				if fmt.Sprintf("%s", event.Op) == "WRITE" {
					debounced(f)
				}
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Error(err)
			}
		}
	}()

	// Add a path.
	err = watcher.Add(".")
	if err != nil {
		log.Error(err)
		return
	}

	// Block main goroutine forever.
	<-make(chan struct{})
}
