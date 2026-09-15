package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"sync"
	"sync/atomic"
	"time"
)

type BenchResult struct {
	TotalRequests int
	SuccessCount  int
	ErrorCount    int
	StatusCounts  map[int]int
	Duration      time.Duration
	RPS           float64
	MinLat        time.Duration
	MaxLat        time.Duration
	P50           time.Duration
	P90           time.Duration
	P95           time.Duration
	P99           time.Duration
	BytesReceived int64
}

func runBenchmark(baseURL string, path string, concurrency int, totalRequests int) BenchResult {
	targetURL := baseURL + path
	client := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        1000,
			MaxIdleConnsPerHost: 500,
			IdleConnTimeout:     60 * time.Second,
			DisableKeepAlives:   false,
			TLSClientConfig:     &tls.Config{InsecureSkipVerify: true},
		},
	}

	latencies := make([]time.Duration, 0, totalRequests)
	var latMutex sync.Mutex
	statusCounts := make(map[int]int)
	var statusMutex sync.Mutex

	var successCount int64
	var errorCount int64
	var bytesRecv int64

	reqChan := make(chan struct{}, totalRequests)
	for i := 0; i < totalRequests; i++ {
		reqChan <- struct{}{}
	}
	close(reqChan)

	var wg sync.WaitGroup
	startTime := time.Now()

	for w := 0; w < concurrency; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			localLats := make([]time.Duration, 0, totalRequests/concurrency+10)
			for range reqChan {
				reqStart := time.Now()
				req, err := http.NewRequest("GET", targetURL, nil)
				if err != nil {
					atomic.AddInt64(&errorCount, 1)
					continue
				}
				req.Header.Set("User-Agent", "IntranetAuditBench/2.0")
				req.Header.Set("Accept-Encoding", "gzip, deflate")

				resp, err := client.Do(req)
				lat := time.Since(reqStart)
				localLats = append(localLats, lat)

				if err != nil {
					atomic.AddInt64(&errorCount, 1)
					continue
				}

				body, _ := io.ReadAll(resp.Body)
				resp.Body.Close()
				atomic.AddInt64(&bytesRecv, int64(len(body)))

				statusMutex.Lock()
				statusCounts[resp.StatusCode]++
				statusMutex.Unlock()

				if resp.StatusCode >= 200 && resp.StatusCode < 400 {
					atomic.AddInt64(&successCount, 1)
				} else {
					atomic.AddInt64(&errorCount, 1)
				}
			}

			latMutex.Lock()
			latencies = append(latencies, localLats...)
			latMutex.Unlock()
		}()
	}

	wg.Wait()
	duration := time.Since(startTime)

	sort.Slice(latencies, func(i, j int) bool {
		return latencies[i] < latencies[j]
	})

	var p50, p90, p95, p99, minLat, maxLat time.Duration
	n := len(latencies)
	if n > 0 {
		minLat = latencies[0]
		maxLat = latencies[n-1]
		p50 = latencies[int(float64(n)*0.50)]
		p90 = latencies[int(float64(n)*0.90)]
		p95 = latencies[int(float64(n)*0.95)]
		p99 = latencies[int(float64(n)*0.99)]
	}

	rps := float64(totalRequests) / duration.Seconds()

	return BenchResult{
		TotalRequests: totalRequests,
		SuccessCount:  int(successCount),
		ErrorCount:    int(errorCount),
		StatusCounts:  statusCounts,
		Duration:      duration,
		RPS:           rps,
		MinLat:        minLat,
		MaxLat:        maxLat,
		P50:           p50,
		P90:           p90,
		P95:           p95,
		P99:           p99,
		BytesReceived: bytesRecv,
	}
}

func runSustainedStress(baseURL string, path string, concurrency int, duration time.Duration, pacingDelay time.Duration) BenchResult {
	targetURL := baseURL + path
	client := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        1000,
			MaxIdleConnsPerHost: 500,
			IdleConnTimeout:     60 * time.Second,
			DisableKeepAlives:   false,
		},
	}

	latencies := make([]time.Duration, 0, 50000)
	var latMutex sync.Mutex
	statusCounts := make(map[int]int)
	var statusMutex sync.Mutex

	var totalCount int64
	var successCount int64
	var errorCount int64
	var bytesRecv int64

	stopChan := make(chan struct{})
	time.AfterFunc(duration, func() {
		close(stopChan)
	})

	var wg sync.WaitGroup
	startTime := time.Now()

	for w := 0; w < concurrency; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			localLats := make([]time.Duration, 0, 2000)
			for {
				select {
				case <-stopChan:
					latMutex.Lock()
					latencies = append(latencies, localLats...)
					latMutex.Unlock()
					return
				default:
				}

				reqStart := time.Now()
				req, err := http.NewRequest("GET", targetURL, nil)
				if err != nil {
					atomic.AddInt64(&errorCount, 1)
					atomic.AddInt64(&totalCount, 1)
					continue
				}
				req.Header.Set("User-Agent", "IntranetSustainedBench/2.0")
				req.Header.Set("Accept-Encoding", "gzip, deflate")

				resp, err := client.Do(req)
				lat := time.Since(reqStart)
				localLats = append(localLats, lat)
				atomic.AddInt64(&totalCount, 1)

				if err != nil {
					atomic.AddInt64(&errorCount, 1)
					continue
				}

				body, _ := io.ReadAll(resp.Body)
				resp.Body.Close()
				atomic.AddInt64(&bytesRecv, int64(len(body)))

				statusMutex.Lock()
				statusCounts[resp.StatusCode]++
				statusMutex.Unlock()

				if resp.StatusCode >= 200 && resp.StatusCode < 400 {
					atomic.AddInt64(&successCount, 1)
				} else {
					atomic.AddInt64(&errorCount, 1)
				}

				if pacingDelay > 0 {
					time.Sleep(pacingDelay)
				}
			}
		}()
	}

	wg.Wait()
	actualDuration := time.Since(startTime)

	sort.Slice(latencies, func(i, j int) bool {
		return latencies[i] < latencies[j]
	})

	var p50, p90, p95, p99, minLat, maxLat time.Duration
	n := len(latencies)
	if n > 0 {
		minLat = latencies[0]
		maxLat = latencies[n-1]
		p50 = latencies[int(float64(n)*0.50)]
		p90 = latencies[int(float64(n)*0.90)]
		p95 = latencies[int(float64(n)*0.95)]
		p99 = latencies[int(float64(n)*0.99)]
	}

	rps := float64(totalCount) / actualDuration.Seconds()

	return BenchResult{
		TotalRequests: int(totalCount),
		SuccessCount:  int(successCount),
		ErrorCount:    int(errorCount),
		StatusCounts:  statusCounts,
		Duration:      actualDuration,
		RPS:           rps,
		MinLat:        minLat,
		MaxLat:        maxLat,
		P50:           p50,
		P90:           p90,
		P95:           p95,
		P99:           p99,
		BytesReceived: bytesRecv,
	}
}

func main() {
	baseURL := "http://35.209.228.150"
	if len(os.Args) > 1 {
		baseURL = os.Args[1]
	}

	fmt.Printf("================================================================================\n")
	fmt.Printf("🚀 AUDITORÍA PROFUNDA DE CARGA Y ESTRÉS .NET 10 EN PRODUCCIÓN (mili3: %s)\n", baseURL)
	fmt.Printf("================================================================================\n\n")

	// Phase 1: Dynamic Login Page Concurrency Ladder
	fmt.Printf("📊 FASE 1: MATRIZ DE CONCURRENCIA ESCALONADA (Endpoint: /Account/Login)\n")
	fmt.Printf("--------------------------------------------------------------------------------\n")
	tiers := []struct {
		concurrency int
		requests    int
		desc        string
	}{
		{10, 300, "10 Usuarios (Tráfico Normal)"},
		{36, 500, "36 Desarrolladores (100% Equipos Activos)"},
		{75, 750, "75 Usuarios (Pico de Matrícula Simultánea)"},
		{150, 1000, "150 Usuarios (Estrés Severo 400%%)"},
		{250, 1000, "250 Usuarios (Límite y Saturación Extrema)"},
	}

	for _, tier := range tiers {
		fmt.Printf("🔹 Ejecutando Tier [%s]: %d conc, %d reqs... ", tier.desc, tier.concurrency, tier.requests)
		res := runBenchmark(baseURL, "/Account/Login", tier.concurrency, tier.requests)
		fmt.Printf("DONE (%.2fs)\n", res.Duration.Seconds())
		fmt.Printf("   RPS: %8.1f | Lat P50: %6.1fms | Lat P90: %6.1fms | Lat P99: %6.1fms | Max: %6.1fms | Exito: %d/%d (%.1f%%) | Errs: %d\n",
			res.RPS,
			float64(res.P50.Microseconds())/1000.0,
			float64(res.P90.Microseconds())/1000.0,
			float64(res.P99.Microseconds())/1000.0,
			float64(res.MaxLat.Microseconds())/1000.0,
			res.SuccessCount, res.TotalRequests,
			float64(res.SuccessCount)/float64(res.TotalRequests)*100.0,
			res.ErrorCount,
		)
		time.Sleep(500 * time.Millisecond)
	}

	// Phase 2: Static Asset Throughput (Nginx Gzip + Microcaching)
	fmt.Printf("\n⚡ FASE 2: RENDIMIENTO DE ASSETS ESTÁTICOS / GZIP (Endpoint: /manifest.json)\n")
	fmt.Printf("--------------------------------------------------------------------------------\n")
	resStatic := runBenchmark(baseURL, "/manifest.json", 50, 1500)
	fmt.Printf("   RPS: %8.1f | Lat P50: %6.1fms | Lat P90: %6.1fms | Lat P99: %6.1fms | Max: %6.1fms | Exito: %d/%d (%.1f%%) | Errs: %d | Data: %.2f KB\n",
		resStatic.RPS,
		float64(resStatic.P50.Microseconds())/1000.0,
		float64(resStatic.P90.Microseconds())/1000.0,
		float64(resStatic.P99.Microseconds())/1000.0,
		float64(resStatic.MaxLat.Microseconds())/1000.0,
		resStatic.SuccessCount, resStatic.TotalRequests,
		float64(resStatic.SuccessCount)/float64(resStatic.TotalRequests)*100.0,
		resStatic.ErrorCount,
		float64(resStatic.BytesReceived)/(1024),
	)

	// Phase 3: Dynamic Module Traversal
	fmt.Printf("\n🧩 FASE 3: AUDITORÍA DE MÓDULOS ACTIVOS (Cross-Module Latency)\n")
	fmt.Printf("--------------------------------------------------------------------------------\n")
	modules := []string{"/Modulo01", "/Modulo02", "/Modulo03", "/Modulo04", "/Modulo05", "/Modulo06", "/Modulo07", "/Modulo08", "/Modulo09"}
	for _, mod := range modules {
		resMod := runBenchmark(baseURL, mod, 25, 250)
		fmt.Printf("   %-12s -> RPS: %6.1f | P50: %5.1fms | P95: %5.1fms | Exito: %d/%d | Errs: %d\n",
			mod, resMod.RPS,
			float64(resMod.P50.Microseconds())/1000.0,
			float64(resMod.P95.Microseconds())/1000.0,
			resMod.SuccessCount, resMod.TotalRequests,
			resMod.ErrorCount,
		)
	}

	// Phase 4: Sustained Endurance Test (30 seconds of high pressure with realistic student pacing)
	fmt.Printf("\n🔥 FASE 4: TEST DE RESISTENCIA Y ENDURANCE (30s Continuos @ 50 Usuarios Concurrentes)\n")
	fmt.Printf("--------------------------------------------------------------------------------\n")
	fmt.Printf("   Iniciando sesión activa sostenida (50 estudiantes navegando simultáneamente con 50ms pacing)...\n")
	resEndurance := runSustainedStress(baseURL, "/Account/Login", 50, 30*time.Second, 50*time.Millisecond)
	fmt.Printf("   RESULTADO RESISTENCIA 30s:\n")
	fmt.Printf("   - Peticiones Totales: %d en %.2fs\n", resEndurance.TotalRequests, resEndurance.Duration.Seconds())
	fmt.Printf("   - Throughput Medio:   %.1f req/s\n", resEndurance.RPS)
	fmt.Printf("   - Latencia P50:       %.1f ms\n", float64(resEndurance.P50.Microseconds())/1000.0)
	fmt.Printf("   - Latencia P90:       %.1f ms\n", float64(resEndurance.P90.Microseconds())/1000.0)
	fmt.Printf("   - Latencia P95:       %.1f ms\n", float64(resEndurance.P95.Microseconds())/1000.0)
	fmt.Printf("   - Latencia P99:       %.1f ms\n", float64(resEndurance.P99.Microseconds())/1000.0)
	fmt.Printf("   - Tasa de Éxito:      %d/%d (%.2f%%)\n", resEndurance.SuccessCount, resEndurance.TotalRequests, float64(resEndurance.SuccessCount)/float64(resEndurance.TotalRequests)*100.0)
	fmt.Printf("   - Errores / Drops:    %d\n", resEndurance.ErrorCount)
	fmt.Printf("================================================================================\n")
}
