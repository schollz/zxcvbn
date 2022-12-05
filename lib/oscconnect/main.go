package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"strings"
	"sync"
	"time"

	"github.com/hypebeast/go-osc/osc"
	log "github.com/schollz/logger"
	"github.com/schollz/peerdiscovery"
)

var mu sync.Mutex

var flagRecvHost, flagRecvAddress, flagHost, flagAddress, flagPath string
var flagPort, flagRecvPort int
var hostOrigin string

type Message struct {
	OriginHost  string
	OriginPort  int
	OriginStart time.Time
}

func (m Message) String() string {
	b, _ := json.Marshal(m)
	return string(b)
}

func init() {
	flag.StringVar(&flagHost, "host", "localhost", "osc host")
	flag.IntVar(&flagPort, "port", 10111, "port to use")
	flag.IntVar(&flagRecvPort, "recv-port", 8765, "port to use to receive")
	flag.StringVar(&flagAddress, "addr", "/oscdiscover", "osc address")
	hostOrigin, _ = getIP()
}

func getIP() (host string, err error) {

	ifaces, err := net.Interfaces()
	if err != nil {
		log.Error(err)
		return
	}
	// handle err
	for _, i := range ifaces {
		addrs, errAdd := i.Addrs()
		if errAdd != nil {
			log.Error(errAdd)
			err = errAdd
			return
		}
		// handle err
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			// process IP address
			log.Tracef("ip: %+v", ip.String())
			if strings.HasPrefix(ip.String(), "192") {
				host = ip.String()
			}
		}
	}
	return
}

func server() {

	d := osc.NewStandardDispatcher()
	d.AddMsgHandler("/sync1", func(msg *osc.Message) {
		msgString := msg.Arguments[0].(string)
		var m Message
		err := json.Unmarshal([]byte(msgString), &m)
		if err != nil {
			log.Error(err)
			return
		}
		log.Tracef("recv: %+v", m)

		client := osc.NewClient(m.OriginHost, m.OriginPort)
		msg2 := osc.NewMessage("/sync2")
		msg2.Append(m.String())
		err = client.Send(msg2)
		if err != nil {
			log.Error(err)
		}
	})
	d.AddMsgHandler("/sync2", func(msg *osc.Message) {
		msgString := msg.Arguments[0].(string)
		var m Message
		err := json.Unmarshal([]byte(msgString), &m)
		if err != nil {
			log.Error(err)
			return
		}
		log.Tracef("recv: %+v", m)
		log.Tracef("to-and-from time: %+v", time.Since(m.OriginStart))
	})
	server := &osc.Server{
		Addr:       fmt.Sprintf("0.0.0.0:%d", flagRecvPort),
		Dispatcher: d,
	}
	server.ListenAndServe()
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
			mu.Lock()
			discovered[d.Address] = struct{}{}
			mu.Unlock()
			log.Debugf("norns discovered: %s", d)
			client := osc.NewClient(flagHost, flagPort)
			msg := osc.NewMessage(flagAddress)
			msg.Append(d.Address)
			err := client.Send(msg)
			if err != nil {
				log.Error(err)
			}

			// determine the round-trip time
			for i := 0; i < 10; i++ {
				sendSync1(d.Address)
				time.Sleep(500 * time.Millisecond)
			}

		},
	})
	if err != nil {
		log.Error(err)
	}

}

func sendSync1(address string) (err error) {
	msg := osc.NewMessage("/sync1")
	msg.Append(fmt.Sprint(Message{hostOrigin, flagRecvPort, time.Now()}))
	client := osc.NewClient(address, flagRecvPort)
	err = client.Send(msg)
	if err != nil {
		log.Error(err)
	}
	return
}
