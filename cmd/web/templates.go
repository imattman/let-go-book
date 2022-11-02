package main

import (
	"html/template"
	"net/http"
	"path/filepath"
	"time"

	"snippetbox.mattman.net/internal/models"
)

func humanDate(t time.Time) string {
	return t.Format("02 Jan 2006 at 15:04")
}

type templateData struct {
	CurrentYear     int
	IsAuthenticated bool
	Snippet         *models.Snippet
	Snippets        []*models.Snippet
	Form            any
	Flash           string
}

func (app *application) newTemplateData(r *http.Request) *templateData {
	return &templateData{
		CurrentYear:     time.Now().Year(),
		IsAuthenticated: app.isAuthenticated(r),
		Flash:           app.sessionManager.PopString(r.Context(), "flash"),
	}
}

func newTemplateCache() (map[string]*template.Template, error) {
	cache := make(map[string]*template.Template)

	funcMap := template.FuncMap{
		"humanDate": humanDate,
	}

	// load all page templates
	pages, err := filepath.Glob("./ui/html/pages/*.tmpl")
	if err != nil {
		return nil, err
	}

	for _, page := range pages {
		name := filepath.Base(page)

		//create initial template set with registered functions
		// always include the base template
		ts, err := template.New(name).Funcs(funcMap).ParseFiles("./ui/html/base.tmpl")
		if err != nil {
			return nil, err
		}

		// update the parsed template set to include any partials
		ts, err = ts.ParseGlob("./ui/html/partials/*.tmpl")
		if err != nil {
			return nil, err
		}

		// finally, add the page template to the parsed set
		ts, err = ts.ParseFiles(page)
		if err != nil {
			return nil, err
		}

		cache[name] = ts
	}

	return cache, nil
}
