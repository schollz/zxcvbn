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
)

var flagFilename string

type Output struct {
	Error  string        `json:"error,omitempty"`
	Timing time.Duration `json:"timing"`
	Result []float64     `json:"result,omitempty"`
}

func init() {
	flag.StringVar(&flagFilename, "filename", "", "filename")
}
func main() {
	flag.Parse()
	var out Output
	var err error
	now := time.Now()
	out.Result, err = run()
	if err != nil {
		out.Error = fmt.Sprint(err)
	}
	out.Timing = time.Since(now)
	b, _ := json.Marshal(out)
	fmt.Println(string(b))
}

func run() (top16 []float64, err error) {
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
	win := 0.02
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

	top16 = make([]float64, 16)
	for i, w := range windows {
		if i == 16 {
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
	for _, algo := range []string{"energy", "hfc", "complex", "kl", "specdiff"} {
		for _, threshold := range []float64{1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1} {
			joblist = append(joblist, job{algo, threshold})
		}
	}

	jobs := make(chan job, len(joblist))
	results := make(chan result, len(joblist))

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
	for i := 0; i < len(joblist); i++ {
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