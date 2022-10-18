package main

import (
	"bytes"
	"flag"
	"time"

	"github.com/hypebeast/go-osc/osc"
	log "github.com/schollz/logger"
	"github.com/schollz/peerdiscovery"
)

var flagRecvHost, flagRecvAddress, flagHost, flagAddress, flagPath string
var flagPort int

func init() {
	flag.StringVar(&flagHost, "host", "localhost", "osc host")
	flag.IntVar(&flagPort, "port", 10111, "port to use")
	flag.StringVar(&flagAddress, "addr", "/oscdiscover", "osc address")
}

func main() {
	flag.Parse()
	log.SetLevel("info")

	// discover peers
	discovered := make(map[string]struct{})
	_, err := peerdiscovery.Discover(peerdiscovery.Settings{
		Limit:     -1,
		Payload:   []byte("norns"),
		Delay:     2 * time.Second,
		TimeLimit: 30 * time.Minute,
		Port:      "9889",
		Notify: func(d peerdiscovery.Discovered) {
			if _, ok := discovered[d.Address]; ok {
				return
			}
			if !bytes.Equal(d.Payload, []byte("norns")) {
				return
			}
			// got new address
			log.Debugf("norns discovered: %s", d)
			client := osc.NewClient(flagHost, flagPort)
			msg := osc.NewMessage(flagAddress)
			msg.Append(d.Address)
			err := client.Send(msg)
			if err != nil {
				log.Error(err)
			}
		},
	})
	if err != nil {
		log.Error(err)
	}

}
