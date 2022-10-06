package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/hypebeast/go-osc/osc"
	log "github.com/schollz/logger"
)

var flagFilename string
var flagTopNumber int
var flagHost, flagAddress string
var flagPort, flagID int

type Output struct {
	Error  string        `json:"error,omitempty"`
	Timing time.Duration `json:"timing"`
	Result []float64     `json:"result,omitempty"`
}

func init() {
	flag.StringVar(&flagFilename, "filename", "", "filename")
	flag.IntVar(&flagTopNumber, "num", 16, "max number of onsets")
	flag.IntVar(&flagID, "id", 1, "id to send back")
	flag.StringVar(&flagHost, "host", "localhost", "osc host")
	flag.IntVar(&flagPort, "port", 10111, "port to use")
	flag.StringVar(&flagAddress, "addr", "/progressbar", "osc address")
}

func main() {
	flag.Parse()

	log.SetLevel("error")

	var out Output
	var err error
	now := time.Now()
	out.Result, err = run()
	if err != nil {
		out.Error = fmt.Sprint(err)
	}
	out.Timing = time.Since(now)
	b, _ := json.Marshal(out)

	sendProgress(100)
	client := osc.NewClient(flagHost, flagPort)
	msg := osc.NewMessage("/aubiodone")
	msg.Append(int32(flagID))
	msg.Append(string(b))
	client.Send(msg)

	fmt.Println(string(b))
}

func run() (top16 []float64, err error) {
	defer func() {
		if recover() != nil {
			err = errors.New("panic occurred")
		}
	}()

	onsets, err := getOnsets()
	if err != nil {
		return
	}
	top16, err = findWindows(onsets)
	return
}

func MinMax(array []float64) (float64, float64) {
	var max float64 = array[0]
	var min float64 = array[0]
	for _, value := range array {
		if max < value {
			max = value
		}
		if min > value {
			min = value
		}
	}
	return min, max
}

func findWindows(data []float64) (top16 []float64, err error) {
	min, max := MinMax(data)
	min = 0
	win := 0.05
	type Window struct {
		min, max float64
		data     []float64
	}
	windows := make([]Window, int((max-min)/win))
	j := 0
	for i := min; i < max-win; i += win {
		windows[j] = Window{i, i + win, getRange(data, i, i+win)}
		j++
	}
	sort.Slice(windows, func(i, j int) bool {
		return len(windows[i].data) > len(windows[j].data)
	})

	top16 = make([]float64, flagTopNumber)
	for i, w := range windows {
		if i == flagTopNumber {
			break
		}
		top16[i] = average(w.data)
	}
	sort.Float64s(top16)

	return
}

func average(arr []float64) (result float64) {
	if len(arr) == 0 {
		return 0.0
	}
	sum := 0.0
	for _, v := range arr {
		sum += v
	}
	return sum / float64(len(arr))
}
func getRange(arr []float64, min, max float64) (rng []float64) {
	data := make([]float64, len(arr))
	j := 0
	for _, v := range arr {
		if v >= min && v <= max {
			data[j] = v
			j++
		}
		// assume arr is sorted
		if v > max {
			break
		}
	}
	if j > 0 {
		rng = data[:j]
	}
	return
}

func sendProgress(progress int) (err error) {
	client := osc.NewClient(flagHost, flagPort)
	msg := osc.NewMessage(flagAddress)
	msg.Append(fmt.Sprintf("[%d] determining onsets", flagID))
	msg.Append(int32(progress))
	err = client.Send(msg)
	return
}

func getOnsets() (onsets []float64, err error) {
	if flagFilename == "" {
		err = fmt.Errorf("no filename")
		return
	}
	if _, err = os.Stat(flagFilename); errors.Is(err, os.ErrNotExist) {
		err = fmt.Errorf("%s does not exist", flagFilename)
		return
	}

	type job struct {
		algo      string
		threshold float64
	}

	type result struct {
		result []float64
		err    error
	}

	joblist := []job{}

	for _, algo := range []string{"energy", "hfc", "mkl", "specdiff", "specflux"} {
		for _, threshold := range []float64{1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.05} {
			joblist = append(joblist, job{algo, threshold})
		}
	}

	numJobs := len(joblist)
	jobs := make(chan job, numJobs)
	results := make(chan result, numJobs)

	numCPU := runtime.NumCPU()
	runtime.GOMAXPROCS(numCPU)

	for i := 0; i < numCPU; i++ {
		go func(jobs <-chan job, results chan<- result) {
			for j := range jobs {
				var r result
				var out []byte
				out, r.err = exec.Command("aubioonset", "-i", flagFilename, "-B", "128", "-H", "128", "-t", fmt.Sprint(j.threshold), "-O", j.algo).Output()
				for _, line := range strings.Split(string(out), "\n") {
					num, errNum := strconv.ParseFloat(line, 64)
					if errNum == nil {
						r.result = append(r.result, num)
					}
				}
				results <- r
			}
		}(jobs, results)
	}

	for _, j := range joblist {
		jobs <- j
	}
	close(jobs)

	data := [10000]float64{}
	j := 0
	for i := 0; i < numJobs; i++ {
		sendProgress(int(float64(i) / float64(numJobs) * 100.0))
		r := <-results
		if r.err != nil {
			err = r.err
		} else {
			for _, v := range r.result {
				if j < len(data) {
					data[j] = v
					j++
				}
			}
		}
	}
	onsets = data[:j]
	sort.Float64s(onsets)

	return
}
