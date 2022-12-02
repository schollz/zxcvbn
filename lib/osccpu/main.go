package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/hypebeast/go-osc/osc"
	ps "github.com/mitchellh/go-ps"
	log "github.com/schollz/logger"
)

var flagRecvHost, flagRecvAddress, flagHost, flagAddress, flagPath string
var flagPort int
var flagWaitTime float64
var flagPID int
var flagPName string

func init() {
	flag.StringVar(&flagHost, "host", "localhost", "osc host")
	flag.IntVar(&flagPort, "port", 10111, "port to use")
	flag.StringVar(&flagAddress, "addr", "/osccpu", "osc address")
	flag.Float64Var(&flagWaitTime, "d", 3.0, "delay time in seconds")
	flag.IntVar(&flagPID, "pid", 0, "pid of process")
	flag.StringVar(&flagPName, "n", "scsynth", "process name")
}

func getPID() {
	processes, err := ps.Processes()
	if err != nil {
		panic(err)
	}
	for _, p := range processes {
		if strings.Contains(p.Executable(), flagPName) {
			log.Debugf("found '%s': %d", p.Executable(), p.Pid())
			flagPID = p.Pid()
		}
	}
}
func main() {
	flag.Parse()
	log.SetLevel("info")

	out, err := exec.Command("getconf", "CLK_TCK").Output()
	if err != nil {
		log.Error(err)
		return
	}
	cpuc, errParse := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
	if errParse != nil {
		log.Error(errParse)
		os.Exit(1)
	}
	ttimelast := 0
	for {
		if flagPID == 0 {
			getPID()
			if flagPID == 0 {
				time.Sleep(time.Duration(flagWaitTime) * time.Second)
				continue
			}
		}
		b, err := ioutil.ReadFile(fmt.Sprintf("/proc/%d/stat", flagPID))
		if err != nil {
			time.Sleep(time.Duration(flagWaitTime) * time.Second)
			continue
		}
		fields := strings.Fields(string(b))
		utime, _ := strconv.Atoi(fields[13])
		ktime, _ := strconv.Atoi(fields[14])
		ttime := utime + ktime
		if ttimelast > 0 {
			cpuUsage := float64(ttime-ttimelast) / cpuc / flagWaitTime * 100
			fmt.Printf("%2.3f\n", cpuUsage)
			client := osc.NewClient(flagHost, flagPort)
			msg := osc.NewMessage(flagAddress)
			msg.Append(int32(cpuUsage * 1000))
			err := client.Send(msg)
			if err != nil {
				log.Error(err)
			}
		}
		ttimelast = ttime
		time.Sleep(time.Duration(flagWaitTime) * time.Second)
	}

}
