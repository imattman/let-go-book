package main

import (
	"database/sql"
	"flag"
	"html/template"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/go-playground/form/v4"
	_ "github.com/go-sql-driver/mysql"
	"snippetbox.mattman.net/internal/models"
)

type application struct {
	errorLog      *log.Logger
	infoLog       *log.Logger
	snippets      *models.SnippetModel
	templateCache map[string]*template.Template
	enableCache   bool
	formDecoder   *form.Decoder
}

func main() {
	addr := flag.String("addr", ":4000", "HTTP network address and port")
	// note: parseTime=true is driver-specific config to convert datetimes to time.Time
	//dsn := flag.String("dsn", "web:dev@/snippetbox?parseTime=true", "MySQL datasouce name")
	dsn := flag.String("dsn", "web:dev@/snippetbox?parseTime=true&charset=utf8mb4&collation=utf8mb4_unicode_ci", "MySQL datasouce name")
	noCache := flag.Bool("nocache", false, "disable template caching")
	flag.Parse()

	infoLog := log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime)
	errorLog := log.New(os.Stderr, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile)

	db, err := openDB(*dsn)
	if err != nil {
		errorLog.Fatal(err)
	}
	defer db.Close()

	// initialize template cache
	templateCache, err := newTemplateCache()
	if err != nil {
		errorLog.Fatal(err)
	}

	formDecoder := form.NewDecoder()

	app := &application{
		errorLog:      errorLog,
		infoLog:       infoLog,
		snippets:      &models.SnippetModel{DB: db},
		templateCache: templateCache,
		enableCache:   !*noCache,
		formDecoder:   formDecoder,
	}

	srv := &http.Server{
		Addr:     *addr,
		ErrorLog: errorLog,
		Handler:  app.routes(),
	}

	infoLog.Printf("Starting server on %s", *addr)
	err = srv.ListenAndServe()
	if err != nil {
		errorLog.Fatal(err)
	}
}

func openDB(dsn string) (*sql.DB, error) {
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, err
	}

	// verify the connection is good
	if err := db.Ping(); err != nil {
		return nil, err
	}

	return db, nil
}

func disableDirListing(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/") {
			http.NotFound(w, r)
			return
		}

		next.ServeHTTP(w, r)
	})
}
