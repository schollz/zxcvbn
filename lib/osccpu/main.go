package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/hypebeast/go-osc/osc"
	ps "github.com/mitchellh/go-ps"
	log "github.com/schollz/logger"
	"github.com/schollz/peerdiscovery"
)

var mu sync.Mutex

var flagRecvHost, flagRecvAddress, flagHost, flagAddress, flagPath string
var flagPort int
var flagWaitTime float64
var flagPID int

func init() {
	flag.StringVar(&flagHost, "host", "localhost", "osc host")
	flag.IntVar(&flagPort, "port", 10111, "port to use")
	flag.StringVar(&flagAddress, "addr", "/oscdiscover", "osc address")
	flag.Float64Var(&flagWaitTime, "delay", 3.0, "delay time in seconds")
	flag.IntVar(&flagPID, "pid", 0, "pid of process")
}

func main() {
	flag.Parse()
	log.SetLevel("info")

	processes, err := ps.Processes()
	if err != nil {
		panic(err)
	}
	pid := 0
	for _, p := range processes {
		if p.Executable() == "scsynth" {
			pid = p.PPid()
		}
	}

	if true == false {
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
			},
		})
		if err != nil {
			log.Error(err)
		}

	}

	cpuc := 100.0
	ttimelast := 0
	for {
		time.Sleep(time.Duration(flagWaitTime) * time.Second)
		b, err := ioutil.ReadFile(fmt.Sprintf("/proc/%d/stat", flagPID))
		if err != nil {
			continue
		}
		fields := strings.Fields(string(b))
		utime, _ := strconv.Atoi(fields[13])
		ktime, _ := strconv.Atoi(fields[14])
		ttime := utime + ktime
		if ttimelast > 0 {
			cpuUsage := float64(ttime-ttimelast) / cpuc / flagWaitTime * 100
			fmt.Printf("cpu usage: %2.3f\n", cpuUsage)
		}
		ttimelast = ttime
	}

}
