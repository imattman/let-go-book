package main

import (
	"bytes"
	"fmt"
	"net/http"
	"runtime/debug"
)

func (app *application) render(w http.ResponseWriter, status int, page string, data *templateData) {
	if !app.enableCache {
		cache, err := newTemplateCache()
		if err != nil {
			app.serverError(w, err)
			return
		}
		app.templateCache = cache
	}

	ts, ok := app.templateCache[page]
	if !ok {
		err := fmt.Errorf("the template %q does not exist", page)
		app.serverError(w, err)
		return
	}

	// validate correct template rendering by initially writing to a buffer
	var buf bytes.Buffer
	err := ts.ExecuteTemplate(&buf, "base", data)
	if err != nil {
		app.serverError(w, err)
		return
	}

	// no errors were encountered so continue down the happy path
	w.WriteHeader(status)
	buf.WriteTo(w)
}

func (app *application) serverError(w http.ResponseWriter, err error) {
	trace := fmt.Sprintf("%s\n%s", err.Error(), debug.Stack())
	app.errorLog.Output(2, trace) // report error location from 2 stack frames up

	http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
}

func (app *application) clientError(w http.ResponseWriter, httpStatus int) {
	http.Error(w, http.StatusText(httpStatus), httpStatus)
}

func (app *application) notFound(w http.ResponseWriter) {
	app.clientError(w, http.StatusNotFound)
}
