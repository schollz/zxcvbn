package main

import (
	"fmt"
	"math/rand"
	"sort"
	"time"
)

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

func sumRowDiffs(matrix [][]float64) (sum float64) {
	for row := range matrix {
		if row == 0 {
			continue
		}
		for col := range matrix[row] {
			sum += (matrix[row][col] - matrix[row-1][col])
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

func main() {
	// load matrices
	// TODO: make all have the same number of columns
	var a = make([][]float64, 10)
	a[0] = []float64{0, 4, 7, 0}
	a[1] = []float64{4, 7, 11, 4}
	a[2] = []float64{9, 0, 4, 9}
	a[3] = []float64{5, 9, 0, 5}
	for i, v := range a {
		if len(v) == 0 {
			a = a[:i]
			break
		}
	}
	type Result struct {
		matrix  [][]float64
		rowDiff float64
	}
	numTries := 1000
	results := make([]Result, numTries)
	rand.Seed(int64(time.Now().Nanosecond()))
	for i := 0; i < numTries; i++ {
		for j, v := range a {
			a[j] = rotate(v, rand.Intn(len(v)))
		}
		results[i] = Result{a, sumRowDiffs(a)}
	}

	sort.Slice(results, func(i, j int) bool {
		return results[i].rowDiff < results[j].rowDiff
	})
	fmt.Println(results[0])
	printMatrix(results[0].matrix)
}
