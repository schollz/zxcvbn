package main

import (
	"flag"
	"fmt"
	"math"
	"os/exec"
	"strconv"
	"strings"
)

var flagFilename string

func init() {
	flag.StringVar(&flagFilename, "filename", "", "filename")
}
func main() {
	flag.Parse()
	err := run()
	if err != nil {
		panic(err)
	}
}

func run() (err error) {
	if flagFilename == "" {
		err = fmt.Errorf("no filename")
	}

	onsets := []float64{}
	onsetMap := make(map[int][]int)
	_ = onsets
	for _, algo := range []string{"energy", "hfc", "complex", "kl", "specdiff"} {
		for _, threshold := range []float64{1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1} {
			var out []byte
			out, err = exec.Command("aubioonset", "-i", flagFilename, "-B", "128", "-H", "128", "-t", fmt.Sprint(threshold), "-O", algo).Output()
			for _, line := range strings.Split(string(out), "\n") {
				num, errNum := strconv.ParseFloat(line, 64)
				if errNum == nil {
					numInt := int(num * 1000)
					// find closest
					found := false
					for k, v := range onsetMap {
						if math.Abs(float64(numInt-k)) < 10 {
							onsetMap[numInt] = append(v, numInt)
							found = true
							break
						}
					}
					if !found {
						onsetMap[numInt] = []int{numInt}
					}
				}
			}
		}
	}
	fmt.Println(onsetMap)

	// TODO do averages

	// local onsets={}
	// for _,algo in ipairs({"energy","hfc","complex","kl","specdiff"}) do
	//   for threshold=1.0,0.1,-0.1 do
	//     local cmd=string.format("aubioonset -i %s -B 128 -H 128 -t %2.1f -O %s",fname,threshold,algo)
	//     print(cmd)
	//     local s=util.os_capture(cmd)
	//     for w in s:gmatch("%S+") do
	//       local wn=tonumber(w)
	//       if math.abs(duration-wn)>0.1 then
	//         local found=false
	//         for i,o in ipairs(onsets) do
	//           if math.abs(wn-average(o.onset))<0.01 then
	//             found=true
	//             onsets[i].count=onsets[i].count+1
	//             table.insert(onsets[i].onset,wn)
	//             break
	//           end
	//         end
	//         if not found then
	//           table.insert(onsets,{onset={wn},count=1})
	//         end
	//       end
	//     end
	//   end
	// end
	return
}
