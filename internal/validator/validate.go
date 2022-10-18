package validator

import (
	"strings"
	"unicode/utf8"
)

type Validator struct {
	FieldErrors map[string]string
}

func (v *Validator) Valid() bool {
	return len(v.FieldErrors) == 0
}

func (v *Validator) AddFieldError(key string, message string) {
	if v.FieldErrors == nil {
		v.FieldErrors = make(map[string]string)
	}

	// only add the first message for a given key
	if _, exists := v.FieldErrors[key]; !exists {
		v.FieldErrors[key] = message
	}
}

// CheckField adds an error message only if a validation check is not "ok"
func (v *Validator) CheckField(ok bool, key string, message string) {
	if !ok {
		v.AddFieldError(key, message)
	}
}

// NotBlank returns true if a value is not an empty string.
func NotBlank(v string) bool {
	return strings.TrimSpace(v) != ""
}

// MaxChars returns true if a value is not longer than n characters.
func MaxChars(v string, n int) bool {
	return utf8.RuneCountInString(v) <= n
}

// PermittedInt returns true if a value is in list of permitted integers.
func PermittedInt(v int, permittedValues ...int) bool {
	for _, p := range permittedValues {
		if v == p {
			return true
		}
	}

	return false
}
