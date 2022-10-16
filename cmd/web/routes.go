package main

import (
	"net/http"

	"github.com/justinas/alice"
)

func (app *application) routes() http.Handler {

	mux := http.NewServeMux()

	// server static files from ./ui/static at URI base /static
	fileServer := http.FileServer(http.Dir("./ui/static/"))
	mux.Handle("/static/", disableDirListing(http.StripPrefix("/static", fileServer)))

	mux.HandleFunc("/", app.home)
	mux.HandleFunc("/snippet/view", app.snippetView)
	mux.HandleFunc("/snippet/create", app.snippetCreate)

	// create middleware chain via Alice convenience library
	standard := alice.New(app.recoverPanic, app.logRequest, secureHeaders)

	return standard.Then(mux)
}
