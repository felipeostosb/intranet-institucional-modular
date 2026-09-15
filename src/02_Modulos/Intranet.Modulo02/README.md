# 📁 Intranet.Modulo02 (Módulo de Asistencia — Equipo 02)

¡Bienvenidos al **Módulo 02 (Control de Asistencia & Deserción Estudiantil)**! Este módulo implementa la lógica completa de registro de sesiones en tiempo real, toma de lista rápida para docentes, semáforo preventivo para estudiantes y la **Regla de Oro DPI (30% de inasistencias)** estipulada en el **Manual de Procesos Académicos (MPA 2024–2026 - R.D. N° 109-V-DIR-2024)** y la directiva **RVM N° 177-2021-MINEDU**.

---

## 🚀 Arquitectura y Reglas de Trabajo (Zero-Blast-Radius)

1. **📁 Carpeta Exclusiva:** Todo el código del módulo reside en `src/02_Modulos/Intranet.Modulo02/`.
2. **🌐 Ruta Web:** Se accede en `/Modulo02`.
   * `/Modulo02` : Dashboard principal con KPIs y sesiones recientes.
   * `/Modulo02/TomarAsistencia/{sesionId}` : Interfaz ergonómica docente para toma de lista en 1 clic.
   * `/Modulo02/MiAsistencia` : Portal del alumno con medidor de horas restantes antes de DPI.
   * `/Modulo02/DetalleCurso/{unidadDidacticaId}` : Historial detallado clase por clase y botón de justificación.
   * `/Modulo02/Justificaciones` : Bandeja de revisión y resolución de justificaciones con sustento.
   * `/Modulo02/ReportesDpi` : Matriz institucional de riesgo DPI para secretaría académica y directivos.
3. **🗄️ Esquema PostgreSQL:** Esquema `mod02` en `db_intranet_iestp` (Usuario: `user_equipo02`).
4. **🎨 Identidad Visual:** Color **Indigo Pastel** (`#4f46e5`), Tailwind CSS y componentes DaisyUI.

---

## 🗄️ Tablas y Vistas del Esquema `mod02`

* `mod02.configuracion` : Parámetros de tolerancia (15 min), límite DPI (30.0%) y días para justificar (72h).
* `mod02.sesiones_clase` : Sesiones programadas y dictadas por unidad didáctica, docente, aula y semana (1 a 18).
* `mod02.asistencias` : Registro individual por estudiante con estados `PRESENTE`, `TARDANZA`, `FALTA_INJUSTIFICADA`, `FALTA_JUSTIFICADA`.
* `mod02.justificaciones` : Solicitudes de justificación con motivo (`Salud_Medica`, `Laboral`, etc.) y URL de documento adjunto.
* `mod02.v_resumen_asistencia_estudiante` : Vista analítica que calcula automáticamente el porcentaje de inasistencia acumulada respecto a las horas totales de la asignatura y genera el semáforo (`REGULAR`, `ALERTA`, `RIESGO_ALTO`, `DPI`).

---

## ⚡ Regla DPI Oficial MINEDU (Art. 8.8.1 MPA)

$$\text{Porcentaje de Inasistencias} = \left( \frac{\text{Total Horas Falta Injustificada}}{\text{Total Horas Semestrales Programadas de la UD}} \right) \times 100$$

* Si el porcentaje acumulado es $\ge 30\%$, el alumno entra en condición **DPI**, inhabilitando su acceso a evaluaciones con nota oficial de **00 (cero)** sin derecho a recuperación.
