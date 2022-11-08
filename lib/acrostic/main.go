package main

import (
	"fmt"
	"math"
	"math/rand"
	"sort"
	"time"
)

var notes = []string{"c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"}

func rotate(nums []float64, k int) []float64 {
	if len(nums) == 0 {
		return nums
	}
	for {
		if k == 0 {
			return nums
		} else if k < 0 {
			k = k + len(nums)
		} else {
			break
		}
	}

	r := len(nums) - k%len(nums)
	nums = append(nums[r:], nums[:r]...)

	return nums
}

func noteDiff(num1, num2 float64) (diff float64) {
	diff = 1000000.0
	for _, add1 := range []float64{0} {
		for _, add2 := range []float64{0} {
			d := math.Abs((num1 + add1) - (num2 + add2))
			if d < diff {
				diff = d
			}
		}
	}
	return
}

func sumRowDiffs(matrix [][]float64) (sum float64) {
	for row := range matrix {
		if row == 0 {
			continue
		}
		for col := range matrix[row] {
			sum += noteDiff(matrix[row][col], matrix[row-1][col])
		}
	}
	return
}

func printMatrix(m [][]float64) {
	for row := range m {
		for col := range m[row] {
			fmt.Printf("%2.0f\t", m[row][col])
		}
		fmt.Print("\n")
	}
}

func printMatrixS(m [][]string) {
	for row := range m {
		for col := range m[row] {
			fmt.Printf("%s\t", m[row][col])
		}
		fmt.Print("\n")
	}
}

func numToNote(num float64) string {
	for {
		if num >= 0 {
			break
		}
		num += 12
	}
	return notes[int(math.Mod(num, 12))]
}

func rearrangeMatrix(m [][]float64) [][]float64 {
	type Result struct {
		matrix  [][]float64
		rowDiff float64
	}
	numTries := 1000
	results := make([]Result, numTries)
	rand.Seed(int64(time.Now().Nanosecond()))
	for i := 0; i < numTries; i++ {
		for j, v := range m {
			m[j] = rotate(v, rand.Intn(len(v)))
		}
		results[i] = Result{m, sumRowDiffs(m)}
	}

	sort.Slice(results, func(i, j int) bool {
		return results[i].rowDiff > results[j].rowDiff
	})
	return results[0].matrix
}

func assignNotes(m [][]float64) (m2 [][]string) {
	m2 = make([][]string, len(m))
	octaves := []int{0, 1, 2, 3, 4, 5}
	for row := range m {
		m2[row] = make([]string, len(m[row]))
		for col := range m[row] {
			m2[row][col] = fmt.Sprintf("%s%d", numToNote(m[row][col]), octaves[col]) //+rand.Intn(2))
		}
	}
	return
}

func main() {
	// load matrices
	// TODO: make all have the same number of columns
	var a = make([][]float64, 10)
	a[0] = []float64{0, 4, 7, 12, 16, 7 - 12}
	a[1] = []float64{4, 7, 11, 4 + 12, 7 + 12, 11 - 12}
	a[2] = []float64{9, 0, 4, 9 - 12, 12, 4 + 12}
	a[3] = []float64{5, 9, 0, 5 + 12, 9 - 12, 0 + 12}
	for i, v := range a {
		if len(v) == 0 {
			a = a[:i]
			break
		}
	}
	m2 := assignNotes(rearrangeMatrix(a))
	printMatrixS(m2)
}
