package env

import (
	"io/ioutil"
	"log"
	"os"
	"path"
	"strings"
)

var logger = log.New(os.Stderr, "env.go ", log.LstdFlags)

// GHClientSecret client secret for github
var GHClientSecret string

// GHClientID client id for github
var GHClientID string

// MongoHost the host for the mongodb instance
var MongoHost string

// MongoPort the port number on the mongodb instance
var MongoPort string

func init() {
	wd, err := os.Getwd()

	if err != nil {
		logger.Fatalf("Coud not get working directory: %v", err)
	}

	p := path.Join(
		wd,
		"lib/env/.env",
	)

	logger.Printf("Reading env from path: %s", p)

	f, err := os.OpenFile(p, os.O_RDONLY, 04)

	defer f.Close()

	if err != nil {
		logger.Fatalf("Could not open .env file from env package: %v", err)
	}

	b, err := ioutil.ReadAll(f)

	if err != nil {
		logger.Fatalf("Could not read .env file from env package: %v", err)
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

	GHClientID = checkVar(envMap, "GH_CLIENT_ID")
	GHClientSecret = checkVar(envMap, "GH_CLIENT_SECRET")
	MongoHost = checkVar(envMap, "MONGO_HOST")
	MongoPort = checkVar(envMap, "MONGO_PORT")
}

func checkVar(envMap map[string]string, varName string) string {
	if val, ok := envMap[varName]; ok {
		os.Setenv(varName, val)
	}
	return os.Getenv(varName)
}
