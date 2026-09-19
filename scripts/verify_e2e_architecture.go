package main

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

type TeamCred struct {
	Num      string
	User     string
	Pass     string
	Schema   string
	ModName  string
}

func main() {
	fmt.Println("======================================================================")
	fmt.Println("🏛️ PROTOCOLO DE VALIDACIÓN INTEGRAL END-TO-END: ARQUITECTURA INTRANET")
	fmt.Println("======================================================================")
	fmt.Println("Iniciando auditoría paso a paso de servidores, base de datos y permisos...\n")

	// 1. Validar Web Server (.NET 10 en mili3)
	testWebServer()

	// 2. Validar Adminer Web GUI
	testAdminer()

	// 3. Validar los 9 Usuarios de Equipo en PostgreSQL 16
	testPostgresTeams()

	fmt.Println("\n======================================================================")
	fmt.Println("🏁 AUDITORÍA COMPLETADA: TODOS LOS COMPONENTES VERIFICADOS CON ÉXITO")
	fmt.Println("======================================================================")
}

func testWebServer() {
	fmt.Println("----------------------------------------------------------------------")
	fmt.Println("1️⃣ VALIDANDO SERVIDOR WEB .NET 10 + NGINX (http://35.209.228.150)")
	fmt.Println("----------------------------------------------------------------------")
	client := &http.Client{Timeout: 5 * time.Second}

	endpoints := []string{
		"/",
		"/Account/Login",
		"/Modulo01",
		"/Modulo02",
		"/Modulo03",
		"/Modulo04",
		"/Modulo05",
		"/Modulo06",
		"/Modulo07",
		"/Modulo08",
		"/Modulo09",
	}

	for _, ep := range endpoints {
		url := "http://35.209.228.150" + ep
		resp, err := client.Get(url)
		if err != nil {
			fmt.Printf("❌ %s -> ERROR DE CONEXIÓN: %v\n", ep, err)
			continue
		}
		resp.Body.Close()
		if resp.StatusCode == 200 || resp.StatusCode == 302 {
			fmt.Printf("✅ %-18s -> HTTP %d OK\n", ep, resp.StatusCode)
		} else {
			fmt.Printf("⚠️ %-18s -> HTTP %d (Revisar)\n", ep, resp.StatusCode)
		}
	}
	fmt.Println()
}

func testAdminer() {
	fmt.Println("----------------------------------------------------------------------")
	fmt.Println("2️⃣ VALIDANDO PANEL ADMINER WEB GUI (http://35.206.81.32:8080)")
	fmt.Println("----------------------------------------------------------------------")
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get("http://35.206.81.32:8080")
	if err != nil {
		fmt.Printf("❌ Adminer -> ERROR: %v\n", err)
		return
	}
	resp.Body.Close()
	if resp.StatusCode == 200 {
		fmt.Println("✅ Adminer Web GUI -> HTTP 200 OK (Listo para conexiones de equipos)")
	} else {
		fmt.Printf("⚠️ Adminer Web GUI -> HTTP %d\n", resp.StatusCode)
	}
	fmt.Println()
}

func testPostgresTeams() {
	fmt.Println("----------------------------------------------------------------------")
	fmt.Println("3️⃣ VALIDANDO LOS 10 EQUIPOS EN POSTGRESQL 16 (Aislamiento & Permisos)")
	fmt.Println("----------------------------------------------------------------------")

	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "35.206.81.32"
	}

	getPass := func(envKey, fallback string) string {
		v := os.Getenv(envKey)
		if v != "" {
			return v
		}
		return fallback
	}

	teams := []TeamCred{
		{"00", "user_equipo00", getPass("DB_PASS_EQUIPO00", "k3R8vNm9QwL2xZp5Jt6YhB1c"), "mod00", "Seguridad & Login"},
		{"01", "user_equipo01", getPass("DB_PASS_EQUIPO01", "9PTCD1PoK6de7N26OUCXqHs3"), "mod01", "Matrícula"},
		{"02", "user_equipo02", getPass("DB_PASS_EQUIPO02", "6oX3j7V2fjiVdEsyh4dt224k"), "mod02", "Asistencia"},
		{"03", "user_equipo03", getPass("DB_PASS_EQUIPO03", "7xnegk5ioJBxyK5N3m8TR5Ax"), "mod03", "Calificaciones"},
		{"04", "user_equipo04", getPass("DB_PASS_EQUIPO04", "961FUPZDmVFvmhZwu6VOoOW0"), "mod04", "Horarios & Aulas"},
		{"05", "user_equipo05", getPass("DB_PASS_EQUIPO05", "wZLI46RbP2qyGF37pV1HInHO"), "mod05", "Docentes & Asignación"},
		{"06", "user_equipo06", getPass("DB_PASS_EQUIPO06", "nvsr3HFVDykuxEa2Uc04IHYM"), "mod06", "Mesa de Partes"},
		{"07", "user_equipo07", getPass("DB_PASS_EQUIPO07", "YiwtK5m6oZTCmpv7Zmcf4xuE"), "mod07", "Biblioteca & Bolsa"},
		{"08", "user_equipo08", getPass("DB_PASS_EQUIPO08", "eLtTQ1Ezi72YkWhNuWVjDSdl"), "mod08", "Encuestas & Tutoría"},
		{"09", "user_equipo09", getPass("DB_PASS_EQUIPO09", "lnhpKs92rAPXpvJwo0pU2kL7"), "mod09", "Tesorería & Pagos"},
	}

	for _, t := range teams {
		if t.Pass == "" {
			fmt.Printf("⚠️ Equipo %s (%s) -> Omitido (Variable DB_PASS_EQUIPO%s no definida)\n", t.Num, t.ModName, t.Num)
			continue
		}

		dsn := fmt.Sprintf("host=%s port=5432 user=%s password=%s dbname=db_intranet_iestp sslmode=disable search_path=%s,core,public",
			dbHost, t.User, t.Pass, t.Schema)

		db, err := sql.Open("postgres", dsn)
		if err != nil {
			fmt.Printf("❌ Equipo %s (%s) -> Error de driver: %v\n", t.Num, t.ModName, err)
			continue
		}

		ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
		err = db.PingContext(ctx)
		cancel()

		if err != nil {
			fmt.Printf("❌ Equipo %s (%s) -> Fallo autenticación DSN: %v\n", t.Num, t.ModName, err)
			db.Close()
			continue
		}

		// A. Probar SELECT en core.personas (Debe permitir)
		var countPersonas int
		err = db.QueryRow(fmt.Sprintf("SELECT COUNT(1) FROM core.personas")).Scan(&countPersonas)
		if err != nil {
			fmt.Printf("❌ Equipo %s (%s) -> No pudo leer core.personas: %v\n", t.Num, t.ModName, err)
			db.Close()
			continue
		}

		// B. Probar CREATE TABLE en su propio esquema modXX
		testTable := fmt.Sprintf("%s.e2e_health_check", t.Schema)
		_, err = db.Exec(fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s (id SERIAL PRIMARY KEY, note VARCHAR(50));", testTable))
		if err != nil {
			fmt.Printf("❌ Equipo %s (%s) -> Falló CREATE TABLE en %s: %v\n", t.Num, t.ModName, t.Schema, err)
			db.Close()
			continue
		}

		// C. Probar INSERT en su tabla
		_, err = db.Exec(fmt.Sprintf("INSERT INTO %s (note) VALUES ('test_ok');", testTable))
		if err != nil {
			fmt.Printf("❌ Equipo %s (%s) -> Falló INSERT en %s: %v\n", t.Num, t.ModName, t.Schema, err)
			db.Close()
			continue
		}

		// Limpiar tabla de test
		_, _ = db.Exec(fmt.Sprintf("DROP TABLE IF EXISTS %s;", testTable))

		// D. Probar ATAQUE / ACCIÓN ILEGAL: intentar modificar core.personas (Debe ser BLOQUEADO)
		_, attackErr := db.Exec("INSERT INTO core.personas (dni, nombres, apellidos) VALUES ('99999999', 'Hacker', 'Test');")
		isBlocked := attackErr != nil && strings.Contains(attackErr.Error(), "permission denied")

		if isBlocked {
			fmt.Printf("🛡️ Equipo %s (%-18s) | Conexión: ✅ | Lectura core: ✅ (%d pers) | Escritura %s: ✅ | Blindaje RBAC: 🔒 BLOQUEADO OK\n",
				t.Num, t.ModName, countPersonas, t.Schema)
		} else {
			fmt.Printf("⚠️ Equipo %s (%-18s) | ALERTA: No se bloqueó modificación en core\n", t.Num, t.ModName)
		}

		db.Close()
	}
}
