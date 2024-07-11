package main

import (
	"bytes"
	"context"
	"io"
	"sort"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"

	"net/http"

	"github.com/labstack/echo/v4"
)

var (
	KUBECONFIG *rest.Config
	CLIENTSET  *kubernetes.Clientset
)

func init() {
	var err error
	KUBECONFIG, err = rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	CLIENTSET, err = kubernetes.NewForConfig(KUBECONFIG)
	if err != nil {
		panic(err.Error())
	}
}

func main() {
	// get node and nodenames, nodes is sorted by nodename
	nodes, nodenames := getNode()
	
	log := make([]string, len(nodes.Items))
	podLog := getPodLog(nodes, nodenames)

	e := echo.New()
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

func getNode() (*corev1.NodeList, []string) {
	nodes, _ := CLIENTSET.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})

	sort.Slice(nodes.Items, func(i, j int) bool {
		return nodes.Items[i].Name < nodes.Items[j].Name
	})

	nodenames := make([]string, len(nodes.Items))
	for i := 0; i < len(nodes.Items); i++ {
		nodenames[i] = nodes.Items[i].Name
	}

	return nodes, nodenames
}

func getPodLog(nodes *corev1.NodeList, nodenames []string) []*rest.Request {
	podLog := make([]*rest.Request, len(nodes.Items))
	line := int64(len(nodes.Items) - 1)

	pods, err := CLIENTSET.CoreV1().Pods("default").List(context.TODO(), metav1.ListOptions{
		LabelSelector: "app=monlat-agent",
	})
	if err != nil {
		panic(err.Error())
	}

	for _, pod := range pods.Items {
		for i, nodename := range nodenames {
			if pod.Spec.NodeName == nodename {
				podLog[i] = CLIENTSET.CoreV1().Pods("default").GetLogs(pod.Name, &corev1.PodLogOptions{
					TailLines: &line,
				})
			}
		}
	}
	return podLog
}
