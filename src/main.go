package main

import (
	"bytes"
	"context"
	"io"
	"strconv"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"

	"net/http"

	"github.com/labstack/echo/v4"
)

func main() {
	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	e := echo.New()

	nodes, _ := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	podLog := make([]*rest.Request, len(nodes.Items))
	log := make([]string, len(nodes.Items))
	podName := make([]string, len(nodes.Items))
	line := int64(2)
	for i := 1; i <= len(nodes.Items); i++ {
		podName[i-1] = "monlat-agent-" + strconv.Itoa(i)
		podLog[i-1] = clientset.CoreV1().Pods("default").GetLogs(podName[i-1], &corev1.PodLogOptions{
			TailLines: &line,
		})
	}

	e.GET("/metrics", func(c echo.Context) error {
		for i := 0; i < len(nodes.Items); i++ {
			podLogs, err := podLog[i].Stream(context.TODO())
			if err != nil {
				panic(err.Error())
			}
			defer podLogs.Close()

			buf := new(bytes.Buffer)
			_, err = io.Copy(buf, podLogs)
			if err != nil {
				panic(err.Error())
			}
			str := buf.String()
			lines := strings.Split(str, "\n")
			log[i] = strings.Join(lines, "\n")
		}

		laslog := strings.Join(log, "")
		return c.String(http.StatusOK, laslog)
	})

	e.GET("/healthz", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})

	e.Logger.Fatal(e.Start(":9090"))
}
