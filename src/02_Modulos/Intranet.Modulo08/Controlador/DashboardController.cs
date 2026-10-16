using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Login_Administracion_de_Modulos.Controlador
{
    [AllowAnonymous]
    public class DashboardController : Controller
    {
        private void CargarDatosSesion(string nombrePorDefecto, string rolPorDefecto)
        {
            // 1. Obtener Nombre de Usuario (Claims -> Cookie M08_UserName -> Por Defecto)
            string? userName = null;
            if (User?.Identity?.IsAuthenticated == true)
            {
                userName = User.FindFirst(ClaimTypes.Name)?.Value ?? User.Identity.Name;
            }

            if (string.IsNullOrWhiteSpace(userName))
            {
                userName = Request.Cookies["M08_UserName"];
            }

            if (string.IsNullOrWhiteSpace(userName))
            {
                userName = nombrePorDefecto;
            }

            // 2. Obtener Rol de Usuario (Claims -> Cookie M08_UserRol -> Por Defecto)
            string? userRole = null;
            if (User?.Identity?.IsAuthenticated == true)
            {
                userRole = User.FindFirst("RolActivo")?.Value
                    ?? User.FindFirst("RolPrincipal")?.Value
                    ?? User.FindFirst(ClaimTypes.Role)?.Value;
            }

            if (string.IsNullOrWhiteSpace(userRole))
            {
                userRole = Request.Cookies["M08_UserRol"];
            }

            if (string.IsNullOrWhiteSpace(userRole))
            {
                userRole = rolPorDefecto;
            }

            // 3. Obtener bandera de EsDemo
            bool esDemo = (User?.FindFirst("EsDemo")?.Value == "true")
                || (Request.Cookies["M08_EsDemo"] == "true");

            ViewBag.UserName = userName;
            ViewBag.UserRole = userRole;
            ViewBag.EsDemo = esDemo;

            var parts = userName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            ViewBag.UserInitials = parts.Length >= 2
                ? $"{parts[0][0]}{parts[1][0]}".ToUpper()
                : (userName.Length > 0 ? userName[0].ToString().ToUpper() : "US");
        }

        [HttpGet("/Dashboard/Topico")]
        public IActionResult Topico()
        {
            CargarDatosSesion("Lic. Rosa Fernández", "Enfermería (Tópico)");
            return View("~/Vista/Dashboard/Topico.cshtml");
        }

        [HttpGet("/Dashboard/Psicologia")]
        public IActionResult Psicologia()
        {
            CargarDatosSesion("Lic. Juan Psicólogo", "Psicología");
            return View("~/Vista/Dashboard/Psicologia.cshtml");
        }

        [HttpGet("/Dashboard/Docente")]
        public IActionResult Docente()
        {
            CargarDatosSesion("Prof. Carlos Docente", "Docente");
            return View("~/Vista/Dashboard/Docente.cshtml");
        }

        [HttpGet("/Dashboard/Soporte")]
        public IActionResult Soporte()
        {
            CargarDatosSesion("Ing. Mario Soporte", "Jefe de Soporte");
            return View("~/Vista/Dashboard/Soporte.cshtml");
        }

        [HttpGet("/Dashboard/Alumno")]
        public IActionResult Alumno()
        {
            CargarDatosSesion("Estudiante Ana Torres", "Alumno");
            return View("~/Vista/Dashboard/Alumno.cshtml");
        }

        [HttpGet("/Dashboard/Practicante")]
        public IActionResult Practicante()
        {
            CargarDatosSesion("Téc. Luis Practicante", "Practicante");
            return View("~/Vista/Dashboard/Practicante.cshtml");
        }

        [HttpGet("/Dashboard/Secretaria")]
        public IActionResult Secretaria()
        {
            CargarDatosSesion("Lic. Carmen Secretaría", "Secretaría Académica");
            return View("~/Vista/Dashboard/Secretaria.cshtml");
        }

        [HttpGet("/Dashboard/Administrador")]
        public IActionResult Administrador()
        {
            CargarDatosSesion("Administrador del Sistema", "Administrador");
            return View("~/Vista/Dashboard/Administrador.cshtml");
        }

        [HttpGet("/Dashboard/JefeGeneral")]
        [HttpGet("/Dashboard/Jefe")]
        public IActionResult JefeGeneral()
        {
            CargarDatosSesion("Ing. Roberto Alarcón", "Jefe General");
            return View("~/Vista/Dashboard/JefeGeneral.cshtml");
        }

        [HttpGet("/Dashboard/JefeComputacion")]
        [HttpGet("/Dashboard/TallerComputacion")]
        public IActionResult JefeComputacion()
        {
            CargarDatosSesion("Lic. Walter Computación", "Jefe de Taller Computación");
            return View("~/Vista/Dashboard/JefeComputacion.cshtml");
        }

        [HttpGet("/Dashboard/JefeAdministracion")]
        [HttpGet("/Dashboard/TallerAdministracion")]
        public IActionResult JefeAdministracion()
        {
            CargarDatosSesion("Lic. Marcos Administración", "Jefe de Taller Administración");
            return View("~/Vista/Dashboard/JefeAdministracion.cshtml");
        }

        [HttpGet("/Dashboard/JefeContabilidad")]
        [HttpGet("/Dashboard/TallerContabilidad")]
        public IActionResult JefeContabilidad()
        {
            CargarDatosSesion("C.P.C. Elena Contabilidad", "Jefe de Taller Contabilidad");
            return View("~/Vista/Dashboard/JefeContabilidad.cshtml");
        }

        [HttpGet("/Dashboard/EncargadoInventario")]
        [HttpGet("/Dashboard/Inventario")]
        public IActionResult EncargadoInventario()
        {
            CargarDatosSesion("Téc. Sergio Inventario", "Encargado de Inventario");
            return View("~/Vista/Dashboard/EncargadoInventario.cshtml");
        }

        [HttpGet("/Dashboard/Tesoreria")]
        [HttpGet("/Dashboard/Tesorero")]
        public IActionResult Tesoreria()
        {
            CargarDatosSesion("Marta Beatriz Torres", "Tesorería");
            return View("~/Vista/Dashboard/Tesoreria.cshtml");
        }
    }
}
