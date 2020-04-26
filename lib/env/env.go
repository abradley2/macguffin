package env

import (
	"io/ioutil"
	"log"
	"os"
	"strings"
)

var logger = log.New(os.Stderr, "env.go ", log.LstdFlags)

var GH_CLIENT_SECRET string
var GH_CLIENT_ID string

func init() {
	f, err := os.OpenFile("./env/.env", os.O_RDONLY, 04)

	defer f.Close()

	if err != nil {
		f, _ = os.Create("env")
		// logger.Fatalf("Could not open .env file from env package: %e", err)
	}

	b, err := ioutil.ReadAll(f)

	if err != nil {
		logger.Fatalf("Could not read .env file from env package: %e", err)
	}

	envLines := strings.Split(string(b), "\n")

	envMap := make(map[string]string)

	for _, l := range envLines {
		nameVal := strings.Split(l, "=")
		if len(nameVal) < 2 {
			continue
		}
		envMap[strings.Trim(nameVal[0], " \n")] = strings.Trim(nameVal[1], " \n")
	}

	if val, ok := envMap["GH_CLIENT_SECRET"]; ok {
		os.Setenv("GH_CLIENT_SECRET", val)
	}
	GH_CLIENT_SECRET = os.Getenv("GH_CLIENT_SECRET")

	if val, ok := envMap["GH_CLIENT_ID"]; ok {
		os.Setenv("GH_CLIENT_ID", val)
	}
	GH_CLIENT_ID = os.Getenv("GH_CLIENT_ID")
}
