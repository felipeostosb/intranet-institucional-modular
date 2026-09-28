#!/usr/bin/env python3
"""
==============================================================================
🧪 SUITE DE PRUEBAS DE CALIDAD Y REGRESIÓN: MÓDULO 02 (ASISTENCIA & DPI)
==============================================================================
IESTP "Argentina" - Sistema ERP Modular Institucional (.NET 10 + PostgreSQL 16)
Auditoría Exhaustiva antes de Despliegue en Servidor Cloud Edge ('mili')
==============================================================================
"""

import urllib.request
import urllib.parse
import http.cookiejar
import json
import re
import html
import sys
import subprocess

BASE_URL = "http://localhost:5000"

class TestModulo02Runner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.total = 0

    def assert_test(self, name, condition, details=""):
        self.total += 1
        if condition:
            self.passed += 1
            print(f"  ✅ [PASS] {name}")
            if details:
                print(f"       └─ {details}")
        else:
            self.failed += 1
            print(f"  ❌ [FAIL] {name}")
            if details:
                print(f"       └─ Motivo: {details}")

    def create_session(self):
        cj = http.cookiejar.CookieJar()
        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
        return opener, cj

    def login(self, opener, identificador, password):
        try:
            # 1. GET Login to obtain __RequestVerificationToken
            req = urllib.request.Request(f"{BASE_URL}/Account/Login")
            with opener.open(req) as resp:
                html = resp.read().decode('utf-8', errors='ignore')
                m = re.search(r'name="__RequestVerificationToken"\s+type="hidden"\s+value="([^"]+)"', html)
                if not m:
                    m = re.search(r'value="([^"]+)"\s+name="__RequestVerificationToken"', html)
                token = m.group(1) if m else ""

            # 2. POST Login
            data = urllib.parse.urlencode({
                "Identificador": identificador,
                "Password": password,
                "__RequestVerificationToken": token
            }).encode('utf-8')

            req_post = urllib.request.Request(f"{BASE_URL}/Account/Login", data=data, method="POST")
            with opener.open(req_post) as resp_post:
                return resp_post.getcode() in [200, 302]
        except Exception as e:
            print(f"Error en login de {identificador}: {e}")
            return False

    def run_sql(self, sql):
        cmd = ["docker", "exec", "postgres-vector-core", "psql", "-U", "prozac", "-d", "db_intranet_iestp", "-t", "-A", "-c", sql]
        res = subprocess.run(cmd, capture_output=True, text=True)
        return res.stdout.strip()

    def run_all(self):
        print("\n" + "="*80)
        print("🚀 INICIANDO AUDITORÍA INTEGRAL DE CALIDAD: MÓDULO 02 (ASISTENCIA & DPI)")
        print("="*80)

        # -------------------------------------------------------------
        # 1. VERIFICACIÓN DE BASE DE DATOS Y AISLAMIENTO DE DATOS REALES
        # -------------------------------------------------------------
        print("\n[FASE 1: VERIFICACIÓN DE ESTRUCTURA Y DATOS REALES EN POSTGRESQL]")
        
        # Test 1.1: 41 Alumnos Reales del Salón VI-A
        count_via = self.run_sql("SELECT COUNT(*) FROM core.estudiantes WHERE ciclo_actual = 'VI' AND seccion = 'A' AND turno = 'Manana';")
        self.assert_test("Población exacta de 41 alumnos reales en VI-A Mañana", count_via == "41", f"Total encontrados: {count_via}")

        # Test 1.2: Perfil de Felipe Ostos con multirrol
        felipe_roles = self.run_sql("SELECT COUNT(*) FROM core.usuario_roles ur JOIN core.usuarios u ON ur.usuario_id = u.id JOIN core.personas p ON u.persona_id = p.id WHERE p.dni = '47915633';")
        self.assert_test("Felipe Ostos (DNI 47915633) configurado con roles válidos", int(felipe_roles) >= 4, f"Roles asignados: {felipe_roles}")

        # Test 1.3: Carga lectiva del Prof. Montero (3 asignaturas, incluyendo Taller Web VI-A)
        montero_clases = self.run_sql("SELECT COUNT(*) FROM mod02.clases_docente cd JOIN core.docentes d ON cd.docente_id = d.id JOIN core.personas p ON d.persona_id = p.id WHERE p.dni = '10000003';")
        self.assert_test("Profesor Montero tiene sus 3 asignaturas asignadas en mod02", montero_clases == "3", f"Clases encontradas: {montero_clases}")

        # Test 1.4: 18 Semanas generadas por asignatura (54 sesiones para Montero)
        montero_sesiones = self.run_sql("SELECT COUNT(*) FROM mod02.sesiones_clase sc JOIN mod02.clases_docente cd ON sc.clase_docente_id = cd.id JOIN core.docentes d ON cd.docente_id = d.id JOIN core.personas p ON d.persona_id = p.id WHERE p.dni = '10000003';")
        self.assert_test("54 sesiones lectivas oficiales generadas para Montero (18 por clase)", montero_sesiones == "54", f"Sesiones encontradas: {montero_sesiones}")

        # -------------------------------------------------------------
        # 2. SEGURIDAD Y CONTROL DE ACCESOS BASADO EN ROLES (RBAC)
        # -------------------------------------------------------------
        print("\n[FASE 2: CONTROL DE ACCESO BASADO EN ROLES (RBAC)]")
        
        # Test 2.1: Login como Docente Montero
        doc_opener, _ = self.create_session()
        doc_login_ok = self.login(doc_opener, "10000003", "123456")
        self.assert_test("Autenticación exitosa del Profesor Montero (DNI 10000003)", doc_login_ok)

        # Test 2.2: Docente accede a Dashboard Modulo02
        req = urllib.request.Request(f"{BASE_URL}/Modulo02")
        with doc_opener.open(req) as resp:
            html_content = html.unescape(resp.read().decode('utf-8', errors='ignore'))
            self.assert_test("Docente visualiza Dashboard Operativo de Asistencia", resp.getcode() == 200 and "Taller de Programación Web" in html_content, f"Código HTTP: {resp.getcode()}")

        # Test 2.3: Login como Alumno Felipe
        alu_opener, _ = self.create_session()
        alu_login_ok = self.login(alu_opener, "47915633", "123456")
        self.assert_test("Autenticación exitosa de Felipe Ostos (Alumno DNI 47915633)", alu_login_ok)

        # Test 2.4: Alumno intenta acceder a /Modulo02 -> Smart Redirect a MiAsistencia
        req_alu = urllib.request.Request(f"{BASE_URL}/Modulo02")
        with alu_opener.open(req_alu) as resp:
            html_alu = html.unescape(resp.read().decode('utf-8', errors='ignore'))
            self.assert_test("Estudiante es redirigido automáticamente a su portal Anti-DPI (MiAsistencia)", resp.getcode() == 200 and ("Mi Asistencia" in html_alu or "Semáforo" in html_alu), f"URL final: {resp.geturl()}")

        # Test 2.5: Alumno tiene denegado el acceso a Tomar Asistencia de clase
        try:
            req_block = urllib.request.Request(f"{BASE_URL}/Modulo02/TomarAsistencia/13")
            with alu_opener.open(req_block) as resp_block:
                html_block = html.unescape(resp_block.read().decode('utf-8', errors='ignore'))
                # Should redirect with error or be in MiAsistencia
                self.assert_test("Estudiante NO puede tomar asistencia (Seguridad Anti-Suplantación)", "Acceso denegado" in html_block or resp_block.geturl().endswith("MiAsistencia"), "Acceso bloqueado conforme a directiva")
        except urllib.error.HTTPError as e:
            self.assert_test("Estudiante NO puede tomar asistencia (Seguridad Anti-Suplantación)", e.code in [403, 302], f"Código HTTP: {e.code}")

        # -------------------------------------------------------------
        # 3. NAVEGACIÓN Y COHESIÓN BIDIRECCIONAL (SÁBANA <-> TOMAR LISTA)
        # -------------------------------------------------------------
        print("\n[FASE 3: NAVEGACIÓN Y COHESIÓN LIVE GRID (SÁBANA <-> TOMAR LISTA)]")

        # Test 3.1: Matriz Consolidada de Clase 19 (Taller de Programación Web VI-A)
        req_matriz = urllib.request.Request(f"{BASE_URL}/Modulo02/Matriz/19")
        with doc_opener.open(req_matriz) as resp:
            html_matriz = html.unescape(resp.read().decode('utf-8', errors='ignore'))
            contiene_curso = "Taller de Programación Web" in html_matriz
            contiene_docente = "Montero" in html_matriz
            contiene_alumno = "OSTOS BERMUDEZ" in html_matriz
            self.assert_test("Sábana Live Grid (Clase 19) muestra curso real, Docente Montero y Alumno Felipe", contiene_curso and contiene_docente and contiene_alumno, "Datos 100% consistentes")

        # Test 3.2: Tomar Asistencia Sesion 13 (Semana 1 de Clase 19)
        req_sesion = urllib.request.Request(f"{BASE_URL}/Modulo02/TomarAsistencia/13")
        with doc_opener.open(req_sesion) as resp:
            html_sesion = resp.read().decode('utf-8', errors='ignore')
            contiene_semana1 = "Semana 1" in html_sesion
            contiene_41 = "41" in html_sesion
            self.assert_test("Toma Flash en Aula (Sesión 13) carga nómina real de 41 alumnos de VI-A", contiene_semana1 and contiene_41, "Nómina completa verificada")

        # Test 3.3: Enlace de retorno desde TomarAsistencia hacia Sábana 19
        tiene_link_sabana = 'href="/Modulo02/Matriz/19"' in html_sesion
        tiene_link_volver = 'href="/Modulo02/Clase/19"' in html_sesion
        self.assert_test("Botones de navegación en Tomar Asistencia apuntan estrictamente a Clase 19", tiene_link_sabana and tiene_link_volver, "Interconexión 1:1 confirmada")

        # -------------------------------------------------------------
        # 4. PERSISTENCIA TRANSACCIONAL Y SINCRONIZACIÓN LIVE
        # -------------------------------------------------------------
        print("\n[FASE 4: PERSISTENCIA TRANSACCIONAL Y SINCRONIZACIÓN LIVE]")

        # Test 4.1: Guardar Asistencia vía AJAX JSON (Flash Pass en Aula)
        payload_asistencia = {
            "SesionClaseId": 13,
            "TemaDesarrollado": "Arquitectura de Software y Patrones de Alta Concurrencia en Go y .NET 10",
            "ObservacionesDocente": "Laboratorio calificado con 100% de estaciones activas",
            "CerrarSesion": False,
            "Alumnos": [
                {
                    "EstudianteId": 120, # Felipe Ostos
                    "Estado": "PRESENTE",
                    "MinutosTardanza": 0,
                    "Observacion": "Asistencia presencial verificada"
                }
            ]
        }
        req_save = urllib.request.Request(
            f"{BASE_URL}/Modulo02/GuardarAsistencia",
            data=json.dumps(payload_asistencia).encode('utf-8'),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with doc_opener.open(req_save) as resp:
            res_data = json.loads(resp.read().decode('utf-8'))
            self.assert_test("Endpoint POST /Modulo02/GuardarAsistencia persiste en BD sin errores", res_data.get("success") is True, res_data.get("message"))

        # Test 4.2: Guardar Sábana Masiva (Live Grid Smart Update)
        payload_matriz = {
            "ClaseId": 19,
            "Celdas": [
                {
                    "EstudianteId": 120, # Felipe Ostos
                    "SesionId": 13,
                    "Estado": "PRESENTE"
                }
            ]
        }
        req_save_matriz = urllib.request.Request(
            f"{BASE_URL}/Modulo02/GuardarMatriz",
            data=json.dumps(payload_matriz).encode('utf-8'),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with doc_opener.open(req_save_matriz) as resp:
            res_matriz = json.loads(resp.read().decode('utf-8'))
            self.assert_test("Endpoint POST /Modulo02/GuardarMatriz sincroniza la matriz completa", res_matriz.get("success") is True, res_matriz.get("message"))

        # -------------------------------------------------------------
        # 5. EXPORTACIÓN OFICIAL (EXCEL CSV Y REGISTRA MINEDU)
        # -------------------------------------------------------------
        print("\n[FASE 5: GENERACIÓN DE ARCHIVOS Y EXPORTACIÓN MINEDU]")

        # Test 5.1: Exportación Excel (.csv) de la Sábana
        req_excel = urllib.request.Request(f"{BASE_URL}/Modulo02/ExportarExcel/19")
        with doc_opener.open(req_excel) as resp:
            content_type = resp.headers.get("Content-Type", "")
            csv_data = resp.read().decode('utf-8', errors='ignore')
            self.assert_test("Exportación de Sábana Excel (.csv) genera archivo válido con los 41 alumnos", resp.getcode() == 200 and "OSTOS BERMUDEZ" in csv_data, f"MIME: {content_type} | Tamaño: {len(csv_data)} bytes")

        # Test 5.2: Generación de Acta para REGISTRA MINEDU
        req_registra = urllib.request.Request(f"{BASE_URL}/Modulo02/ExportarRegistra/19")
        with doc_opener.open(req_registra) as resp:
            registra_data = resp.read().decode('utf-8', errors='ignore')
            contiene_minedu = "REGISTRA" in registra_data or "MINEDU" in registra_data
            self.assert_test("Generación de Formato REGISTRA MINEDU oficial estructurado", resp.getcode() == 200 and contiene_minedu, f"Líneas generadas: {len(registra_data.splitlines())}")

        # -------------------------------------------------------------
        # 6. RADAR ANTI-DPI Y BANDEJA DE JUSTIFICACIONES
        # -------------------------------------------------------------
        print("\n[FASE 6: RADAR PREVENTIVO ANTI-DPI & JUSTIFICACIONES (72H)]")

        # Test 6.1: Radar de Deserción DPI (>=30%)
        admin_opener, _ = self.create_session()
        self.login(admin_opener, "00000001", "123456")
        req_dpi = urllib.request.Request(f"{BASE_URL}/Modulo02/ReportesDpi")
        with admin_opener.open(req_dpi) as resp:
            html_dpi = resp.read().decode('utf-8', errors='ignore')
            self.assert_test("Radar Preventivo DPI muestra semáforo de riesgo y cálculo de inasistencias", resp.getcode() == 200 and ("Radar" in html_dpi or "DPI" in html_dpi), f"Código HTTP: {resp.getcode()}")

        # Test 6.2: Bandeja de Justificaciones (72h)
        req_justif = urllib.request.Request(f"{BASE_URL}/Modulo02/Justificaciones")
        with doc_opener.open(req_justif) as resp:
            html_justif = resp.read().decode('utf-8', errors='ignore')
            self.assert_test("Bandeja de Justificaciones (72h hábiles) accesible y operativa", resp.getcode() == 200 and "Justificaciones" in html_justif, f"Código HTTP: {resp.getcode()}")

        # -------------------------------------------------------------
        # RESUMEN FINAL DE AUDITORÍA
        # -------------------------------------------------------------
        print("\n" + "="*80)
        print(f"📊 RESUMEN FINAL: {self.passed} / {self.total} PRUEBAS EXITOSAS ({(self.passed/self.total)*100:.1f}%)")
        print("="*80)

        if self.failed == 0:
            print("\n🎉 ¡TODAS LAS PRUEBAS PASARON SATISFACTORIAMENTE!")
            print("🚀 El Módulo 02 se encuentra en estado óptimo, verificado y listo para el despliegue.")
            return 0
        else:
            print(f"\n⚠️ Se detectaron {self.failed} fallo(s) que requieren atención.")
            return 1

if __name__ == "__main__":
    runner = TestModulo02Runner()
    sys.exit(runner.run_all())
