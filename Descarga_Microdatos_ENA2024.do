clear all
set more off
version 16.0

* 1. CONFIGURACIÓN DEL SERVIDOR INEI Y CARPETA TEMPORAL
local baseurl "https://proyectos.inei.gob.pe/iinei/srienaho/descarga/STATA"
capture mkdir "Descargas_INEI_ZIP"

display as result _n "══════════════════════════════════════════════════════════════════"
display as result " DESCARGANDO Y DESCOMPRIMIENDO MÓDULOS ENA 2024 (INEI)..."
display as result "══════════════════════════════════════════════════════════════════"

* 2. BUCLE SIMPLE PARA DESCARGAR Y DESCOMPRIMIR LOS DOS MÓDULOS (1895 Y 1911)
foreach mod in 1895 1911 {
    display as text _n "--> Procesando Módulo `mod'..."
    
    * Descargar ZIP oficial desde el servidor del INEI
    capture copy "`baseurl'/973-Modulo`mod'.zip" "Descargas_INEI_ZIP/Modulo`mod'.zip", replace
    
    * Descomprimir nativamente (Stata extraerá la carpeta 973-Modulo`mod')
    capture unzipfile "Descargas_INEI_ZIP/Modulo`mod'.zip", replace
}

* 3. LIMPIEZA AUTOMÁTICA DE LA CARPETA TEMPORAL ZIP
capture shell rmdir /s /q "Descargas_INEI_ZIP"

* 4. VERIFICACIÓN SIMPLE DE LOS ARCHIVOS
display as result _n "══════════════════════════════════════════════════════════════════"
display as result " RESUMEN FINAL DE DATOS EN DIRECTORIO"
display as result "══════════════════════════════════════════════════════════════════"

capture confirm file "973-Modulo1895\03_CAP200AB.dta"
if _rc == 0  display as green "OK"
if _rc != 0  display as red   "No encontrado"

capture confirm file "973-Modulo1911\19_CAP1100.dta"
if _rc == 0  display as green "OK"
if _rc != 0  display as red   "No encontrado"

display as text _n "Listo para ejecutar"
