package request

import (
	"strings"
	"testing"
)

type testWriter struct {
	bytes []byte
}

func (w *testWriter) Write(b []byte) (int, error) {
	w.bytes = append(w.bytes, b...)

	return len(b), nil
}

func TestLogger(t *testing.T) {
	l := NewLogger()

	w := &testWriter{}
	l.SetOutput(w)

	msg := "some message"
	l.Printf(msg)

	s := string(w.bytes)

	if strings.Contains(s, msg) == false {
		t.Fatalf("Did not find message in output log")
	}
}
