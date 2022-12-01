package main

import (
	"bytes"
	"html/template"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/gosimple/slug"
	log "github.com/schollz/logger"
	"github.com/yuin/goldmark"
	meta "github.com/yuin/goldmark-meta"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/renderer/html"
)

var markdown goldmark.Markdown

type Entry struct {
	Title     string
	Weight    float64
	Command   string
	Range     string
	Shortcode string
	Shortfa   string
	Version   string
	Path      string
	Clades    []string
	Body      template.HTML
}

type Data struct {
	Blurbs      map[string]Entry
	Commands    []Entry
	Clades      []Entry
	Lessons     []Entry
	AllCommands []string
	Changelog   []Entry
	Routing     []Entry
}

func main() {
	log.SetLevel("trace")

	markdown = goldmark.New(
		goldmark.WithExtensions(
			meta.Meta,
		),
		goldmark.WithParserOptions(
			parser.WithAutoHeadingID(),
		),
		goldmark.WithRendererOptions(
			html.WithXHTML(),
			html.WithUnsafe(),
		),
	)
	err := run()
	if err != nil {
		log.Error(err)
	}
}

func run() (err error) {
	// read in template
	b, err := ioutil.ReadFile("template.html")
	if err != nil {
		log.Error(err)
		return
	}
	t := template.New("main").Funcs(template.FuncMap{
		"slugify": func(s string) string {
			return slug.Make(s)
		},
		"lowercase": func(s string) string {
			return strings.ToLower(s)
		},
		"isupper": func(s string) bool {
			return s == strings.ToUpper(s)
		},
	})
	t, err = t.Parse(string(b))
	if err != nil {
		log.Error(err)
		return
	}

	// make build directory
	os.MkdirAll("../build", os.ModePerm)

	// initialize data
	d := Data{Blurbs: make(map[string]Entry)}

	// gather data
	err = filepath.Walk(".",
		func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if info.IsDir() {
				return nil
			}
			path = filepath.ToSlash(path)
			if filepath.Ext(path) == ".md" {
				e, err := ParseEntry(path)
				if err != nil {
					return err
				}
				e.Path = path
				if strings.Contains(path, "commands/") {
					d.Commands = append(d.Commands, e)
				} else if strings.Contains(path, "clades/") {
					d.Clades = append(d.Clades, e)
				} else if strings.Contains(path, "lessons/") {
					d.Lessons = append(d.Lessons, e)
				} else if strings.Contains(path, "blurbs/") {
					d.Blurbs[e.Title] = e
				} else if strings.Contains(path, "routing/") {
					d.Routing = append(d.Routing, e)
				} else if strings.Contains(path, "changelog/") {
					d.Changelog = append(d.Changelog, e)
				}
			}
			return nil
		})
	if err != nil {
		log.Error(err)
		return
	}

	sort.Slice(d.Clades, func(i, j int) bool {
		return d.Clades[i].Weight < d.Clades[j].Weight
	})
	sort.Slice(d.Changelog, func(i, j int) bool {
		return d.Changelog[i].Version > d.Changelog[j].Version
	})
	sort.Slice(d.Commands, func(i, j int) bool {
		return strings.ToLower(d.Commands[i].Shortcode) < strings.ToLower(d.Commands[j].Shortcode)
	})
	sort.Slice(d.Lessons, func(i, j int) bool {
		return d.Lessons[i].Weight < d.Lessons[j].Weight
	})
	sort.Slice(d.Routing, func(i, j int) bool {
		return d.Routing[i].Title < d.Routing[j].Title
	})

	d.AllCommands = make([]string, len(d.Commands))
	i := 0
	for _, v := range d.Commands {
		d.AllCommands[i] = v.Title
		i++
	}
	sort.Strings(d.AllCommands)

	// write build
	var tpl bytes.Buffer
	err = t.Execute(&tpl, d)
	if err != nil {
		log.Error(err)
		return
	}
	err = ioutil.WriteFile("../build/index.html", tpl.Bytes(), 0644)
	if err != nil {
		log.Error(err)
		return
	}

	return
}

func ParseEntry(fname string) (e Entry, err error) {
	b, err := ioutil.ReadFile(fname)
	if err != nil {
		log.Error(err)
		return
	}
	source := string(b)
	var buf bytes.Buffer
	context := parser.NewContext()
	if err = markdown.Convert([]byte(source), &buf, parser.WithContext(context)); err != nil {
		log.Error(err)
		return
	}
	e.Body = template.HTML(buf.String())

	// get metadata
	metaData := meta.Get(context)
	log.Tracef("metaData: %+v", metaData)
	if _, ok := metaData["title"]; ok {
		e.Title = metaData["title"].(string)
	}
	if _, ok := metaData["command"]; ok {
		e.Command = metaData["command"].(string)
	}
	if _, ok := metaData["range"]; ok {
		e.Range = metaData["range"].(string)
	}
	if _, ok := metaData["version"]; ok {
		e.Version = metaData["version"].(string)
	}
	if _, ok := metaData["shortcode"]; ok {
		e.Shortcode = metaData["shortcode"].(string)
		if len(e.Shortcode) > 1 {
			e.Shortfa = e.Shortcode
			e.Shortcode = ""
		}
	}
	if _, ok := metaData["weight"]; ok {
		e.Weight = metaData["weight"].(float64)
	}
	if _, ok := metaData["clades"]; ok {
		for _, v := range metaData["clades"].([]interface{}) {
			e.Clades = append(e.Clades, v.(string))
		}
	}

	return
}
