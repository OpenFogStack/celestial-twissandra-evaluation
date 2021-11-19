package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func getSatId(apiEndpoint string) (int, error) {
	url := fmt.Sprintf("http://%s/self", apiEndpoint)
	resp, err := http.Get(url)
	if err != nil {
		log.Println("couldn't get url", err.Error())
		return 0, err
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Println("couldn't read body", err.Error())
		return 0, err
	}

	resp.Body.Close()

	// what we got was not a json!
	// continue
	if !strings.HasPrefix(string(body), "{") {
		log.Printf("got response: %s (waiting)\n", string(body))
		return 0, errors.New("not yet ready!")
	}

	id := struct {
		Shell int
		Id    int
	}{}

	err = json.Unmarshal(body, &id)
	if err != nil {
		fmt.Println("couldn't parse json", err.Error(), string(body))
		return 0, err
	}

	log.Printf("identifier: %+v", id)
	return id.Id, nil
}

func main() {
	apiEndpoint := flag.String("api-host", "", "The host of the api server (gateway")

	flag.Parse()

	if *apiEndpoint == "" {
		panic("api-host is required")
	}

	// get own id
	var id int
	var err error
	for {
		if id, err = getSatId(*apiEndpoint); err == nil {
			fmt.Println(id)
			break
		}
		time.Sleep(3 * time.Second)
	}

	valid_ids := map[int]struct{}{
		0:    {},
		10:   {},
		20:   {},
		30:   {},
		175:  {},
		185:  {},
		195:  {},
		340:  {},
		350:  {},
		360:  {},
		370:  {},
		515:  {},
		525:  {},
		535:  {},
		680:  {},
		690:  {},
		700:  {},
		710:  {},
		855:  {},
		865:  {},
		875:  {},
		1020: {},
		1030: {},
		1040: {},
		1050: {},
	}

	if _, ok := valid_ids[id]; !ok {
		fmt.Println("id is not valid")
		os.Exit(1)
	}

	f, err := os.Create("id.txt")

	if err != nil {
		log.Fatalf("could not open seeds.txt: %s", err.Error())
	}

	fmt.Printf("id_finder: found id %d\n", id)
	fmt.Fprint(f, id)
	f.Close()
}
