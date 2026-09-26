#!/usr/bin/env bash
# Arranque local de la Intranet Institucional Modular (.NET 10 + MariaDB local)
# Redirige TODAS las conexiones (core + 9 módulos) del servidor remoto del profesor
# hacia el MariaDB local (127.0.0.1:3306, usuario puente intranet_app).
export DOTNET_ROOT=/home/isma/.dotnet
export PATH=/home/isma/.dotnet:$PATH
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export ASPNETCORE_ENVIRONMENT=Development

export ConnectionStrings__DefaultConnection="Server=127.0.0.1;Port=3306;Database=db_core;User=intranet_app;Password=IntranetApp2026;"
for i in 01 02 03 04 05 06 07 08 09; do
  export ConnectionStrings__Modulo${i}Connection="Server=127.0.0.1;Port=3306;Database=db_modulo${i};User=user_equipo${i};Password=Equipo${i}_Pass2026!;"
done

cd /home/isma/projects/intranet-institucional-modular
exec dotnet run --project src/03_Web/Intranet.Web --no-build --urls http://localhost:5000
