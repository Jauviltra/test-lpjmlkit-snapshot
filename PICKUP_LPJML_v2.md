# PICKUP_LPJML — Reproducción e ingredientes (versión integrada)

Última actualización: 2025-11-05

Este documento reúne los hallazgos y pasos prácticos para reproducir cómo se generaron las coordenadas de la submuestra de LPJmL para España, incorpora la reproducción realizada el 2025-11-05 y propone un layout de artefactos en el árbol del proyecto (`output/`) para conservar sólo las versiones finales/útiles.

## Resumen ejecutivo

- Objetivo: reproducir la extracción de ~350 celdas usadas en la corrida local de LPJmL, validar las coordenadas, producir visualizaciones y documentar el procedimiento.
- Resultado: se recrearon con éxito los ficheros de salida (CSV, TXT, GeoJSON) usando la cabecera `spain_v3_clm.hdr` encontrada en el archive, con valores clave:
  - ncell = 350
  - firstcell = 32180
  - scalar = 0.01
  - cellsize = 0.5 (grados)
- Artefactos finales (sugerencia de ubicación): mover las últimas versiones a `output/` y las referencias históricas útiles a `output/legacy/`.

## Qué se hizo (pasos cortos)

1. Localicé la cabecera original en el archivo de archive (`.hdr`) que contiene los parámetros citados arriba.
2. Creé un JSON temporal con esos valores (`spain_v3_clm.json`) y ejecuté el fallback extractor (`grid_cells_extract_safe.R`) porque el extractor original no estaba disponible en el repo.
3. El extractor fallback leyó el binario usando la interpretación adecuada (escala 0.01, orden estándar) y escribió:
   - CSV con columnas `index, lon, lat` (~350 filas)
   - TXT con la lista de índices
   - GeoJSON con puntos (centros de celda)
4. Preparé scripts de plotting en R (ggplot2) que dibujan las celdas como rectángulos de tamaño `cellsize` centradas en las coordenadas.
5. Generé un PNG de comprobación con el mapa de celdas. Se observó que unas pocas celdas quedan fuera de la península (noroeste de África); el filtrado espacial quedó pospuesto.

## Nueva organización de artefactos (recomendación)

Mover sólo las últimas versiones finales a `output/`. Mantener referencias históricas en `output/legacy/`.

- output/
  - spain_v3_recreated_cells.csv  — Coordenadas recreadas (index,lon,lat). (versión final)
  - spain_v3_recreated_cells.txt  — Índices (una columna). (versión final)
  - spain_v3_recreated_cells.geojson — Puntos GeoJSON (centros de celdas). (versión final)
  - spain_v3_clm.json — Cabecera JSON usada para la extracción (ncell, firstcell, scalar, cellsize). (versión final)
  - cells_map_spain_grid_nosf.png — Visualización con celdas como rectángulos. (versión final)
  - extended_detector_results.csv — Resultados del detector extenso (última ejecución relevante). (versión final)

- output/legacy/
  - spain_v3_clm.hdr — Cabecera textual original (desde repos antiguos). (referencia histórica)
  - spain_v3_clm.bin — Binario original (si procede copiarlo, por razones de trazabilidad).
  - any_prior_cells_*.csv — Copias históricas seleccionadas (sólo las que sean útiles para reproducibilidad).

- tmp/ — seguir usando para artefactos intermedios y pruebas. No mantener allí las versiones finales.

Nota: en esta operación sólo trasladaremos las últimas versiones consolidadas (no todas las copias históricas) para evitar redundancia y bloat en el repo.

## Comandos sugeridos para mover/copiar (PowerShell)

A continuación hay ejemplos que puedes ejecutar en PowerShell. Ajusta las rutas si trabajas desde WSL; en WSL puedes usar `mv`/`cp` equivalentes.

# Crear la carpeta de salida si no existe
New-Item -ItemType Directory -Force -Path .\output
New-Item -ItemType Directory -Force -Path .\output\legacy

# Copiar desde tmp/ a output/ (solo las versiones finales)
Copy-Item -Path .\tmp\spain_v3_recreated_cells.csv -Destination .\output\spain_v3_recreated_cells.csv -Force
Copy-Item -Path .\tmp\spain_v3_recreated_cells.txt -Destination .\output\spain_v3_recreated_cells.txt -Force
Copy-Item -Path .\tmp\spain_v3_recreated_cells.geojson -Destination .\output\spain_v3_recreated_cells.geojson -Force
Copy-Item -Path .\tmp\spain_v3_clm.json -Destination .\output\spain_v3_clm.json -Force
Copy-Item -Path .\tmp\cells_map_spain_grid_nosf.png -Destination .\output\cells_map_spain_grid_nosf.png -Force
Copy-Item -Path .\tmp\extended_detector_results.csv -Destination .\output\extended_detector_results.csv -Force

# Copiar referencias de repos antiguos al subdirectorio legacy
Copy-Item -Path "C:\path\to\old_repo\data\spain_v3_clm.hdr" -Destination .\output\legacy\spain_v3_clm.hdr -Force
Copy-Item -Path "C:\path\to\old_repo\data\spain_v3_clm.bin" -Destination .\output\legacy\spain_v3_clm.bin -Force

(Reemplaza C:\path\to\old_repo con la ruta real del repo viejo; estas copias sólo son necesarias si quieres mantener el bin/hdr histórico en el repositorio.)

Comandos equivalentes en WSL / bash:

mkdir -p output output/legacy
cp tmp/spain_v3_recreated_cells.csv output/
cp tmp/spain_v3_recreated_cells.txt output/
cp tmp/spain_v3_recreated_cells.geojson output/
cp tmp/spain_v3_clm.json output/
cp tmp/cells_map_spain_grid_nosf.png output/
cp tmp/extended_detector_results.csv output/
# copias desde archive
cp /home/jvt/old_repos/test-lpjmlkit-*/.archive_202*/data/spain_v3_clm.hdr output/legacy/
cp /home/jvt/old_repos/test-lpjmlkit-*/.archive_202*/data/spain_v3_clm.bin output/legacy/

## Verificación rápida

- Abrir `output/spain_v3_recreated_cells.csv` y comprobar que lon ∈ [-10, +6] y lat ∈ [28, 46] y que tiene ~350 filas.
- Abrir `output/spain_v3_recreated_cells.geojson` en QGIS o con `jq` para inspeccionar las geometrías.
- Visualizar `output/cells_map_spain_grid_nosf.png`.

## Notas sobre decisiones y supuestos

- Conservación: se copian al repo sólo los artefactos finales necesarios para reproducir la extracción y la visualización; los binarios pesados y las múltiples copias antiguas quedan en `output/legacy/` y se documenta su origen.
- Filtrado espacial: no se ha aplicado por ahora. Varias celdas caen fuera de España; si queremos un CSV filtrado por límites administrativos, la siguiente tarea es usar `sf` + GADM y generar `output/spain_v3_recreated_cells_filtered.csv`.
- Extractor original: el extractor citado en la repo original no se encontraba; se usó el `grid_cells_extract_safe.R` (fallback). Guardar `spain_v3_clm.json` en `output/` para trazabilidad (contiene `ncell`, `firstcell`, `scalar`, `cellsize`).

## Siguientes pasos recomendados

1. Ejecutar los comandos de copia arriba para consolidar archivos en `output/`.
2. Revisar `output/spain_v3_recreated_cells.csv`. Si está OK, proceder a commitear `PICKUP_LPJML_v2.md` y los ficheros en `output/`.
3. Opcional: ejecutar un filtrado espacial con `sf` y GADM, y guardar la variante filtrada en `output/`.
4. Opcional: empaquetar las funciones R usadas en `gridbin_to_clm/R/` como helpers reutilizables y añadir pruebas unitarias minimalistas.

## Registro de cambios (breve)

- 2025-11-05: Reproducción y extracción con fallback extractor; CSV/GeoJSON/PNG generados. Documento refundido creado como `PICKUP_LPJML_v2.md`.

---
 
Si quieres, puedo ahora:
- Ejecutar las copias y commitear `PICKUP_LPJML_v2.md` + `output/` (requiere permisos git en el entorno). O bien,
- Generar el script `output/scripts/move_artifacts.ps1` y `output/scripts/move_artifacts.sh` con los comandos mencionados para que los ejecutes localmente. ¿Cuál prefieres?
