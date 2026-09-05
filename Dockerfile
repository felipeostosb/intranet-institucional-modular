# ==============================================================================
# 🏛️ DOCKERFILE SPARTAN .NET 10 (LTS hasta Noviembre 2028)
# Compilación Optimizada Multi-Stage con Alpine Linux
# ==============================================================================

FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

# 1. Copiar archivos de proyectos para restaurar dependencias con caché
COPY ["Directory.Build.props", "./"]
COPY ["src/01_Core/Intranet.Core/Intranet.Core.csproj", "src/01_Core/Intranet.Core/"]
COPY ["src/01_Core/Intranet.Data/Intranet.Data.csproj", "src/01_Core/Intranet.Data/"]
COPY ["src/02_Modulos/Intranet.Modulo01/Intranet.Modulo01.csproj", "src/02_Modulos/Intranet.Modulo01/"]
COPY ["src/02_Modulos/Intranet.Modulo02/Intranet.Modulo02.csproj", "src/02_Modulos/Intranet.Modulo02/"]
COPY ["src/02_Modulos/Intranet.Modulo03/Intranet.Modulo03.csproj", "src/02_Modulos/Intranet.Modulo03/"]
COPY ["src/02_Modulos/Intranet.Modulo04/Intranet.Modulo04.csproj", "src/02_Modulos/Intranet.Modulo04/"]
COPY ["src/02_Modulos/Intranet.Modulo05/Intranet.Modulo05.csproj", "src/02_Modulos/Intranet.Modulo05/"]
COPY ["src/02_Modulos/Intranet.Modulo06/Intranet.Modulo06.csproj", "src/02_Modulos/Intranet.Modulo06/"]
COPY ["src/02_Modulos/Intranet.Modulo07/Intranet.Modulo07.csproj", "src/02_Modulos/Intranet.Modulo07/"]
COPY ["src/02_Modulos/Intranet.Modulo08/Intranet.Modulo08.csproj", "src/02_Modulos/Intranet.Modulo08/"]
COPY ["src/02_Modulos/Intranet.Modulo09/Intranet.Modulo09.csproj", "src/02_Modulos/Intranet.Modulo09/"]
COPY ["src/03_Web/Intranet.Web/Intranet.Web.csproj", "src/03_Web/Intranet.Web/"]

RUN dotnet restore "src/03_Web/Intranet.Web/Intranet.Web.csproj"

# 2. Copiar el código fuente completo y compilar en Release
COPY . .
WORKDIR "/src/src/03_Web/Intranet.Web"
RUN dotnet publish -c Release -o /app/publish --no-restore

# 3. Imagen de Runtime Ultra-Liviana (.NET 10 ASP.NET Alpine)
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS final
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 5000
ENTRYPOINT ["dotnet", "Intranet.Web.dll"]
