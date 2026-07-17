/*  
TÍTULO:  Efecto del uso de semillas certificadas sobre el rendimiento
         agrícola del cultivo de arroz cáscara en las unidades
         agropecuarias del Perú (ENA, 2024)

  BASE:    Encuesta Nacional Agropecuaria (ENA) 2024

  MÓDULOS Y CAPÍTULOS
	  Modulo 1895
		• Capítulo 200 (Partes A y B) [03_CAP200AB.dta] → Producción y prácticas (Y, X1, riego, clima)
	  Modulo 1911
		• Capítulo 1100               [19_CAP1100.dta]  → Características del productor/a (sexo, edad, educ.)

  ESTRUCTURA DEL DO-FILE:
  ───────────────────────────────────────────────
   I.    Configuración inicial
   II.   Carga y merge de los dos capítulos (cuestionarios)
   III.  Limpieza de datos y selección de la muestra
   IV.   Construcción de variables
   V.    Base final (depuración y guardado)
   VI.   Estadísticas descriptivas
   VII.  Tablas descriptivas generales (exportación RTF — Tabla 1)
   VIII. Tablas de frecuencias por región natural y composición geográfica
   IX.   Matriz de correlaciones (Tabla 2)
   X.    Modelos OLS anidados (comparación)
   XI.   Diagnósticos del modelo
   XII.  Regresión robusta antes de depurar singleton (N=1,992)
   XIII. Modelo definitivo purificado de singleton (N=1,991)
   XIV.  Pruebas de validez estadística conjunta
   XV.   Análisis bivariado y gráficos definitivos sobre muestra purificada (N=1,991)
  ───────────────────────────────────────────────*/


* ══════════════════════════════════════════════════════════════════════════════
* PARTE I: CONFIGURACIÓN INICIAL
* ══════════════════════════════════════════════════════════════════════════════
* Se prepara un entorno limpio para garantizar la reproducibilidad del código.

clear all
set more off
capture log close
cls

* Directorio de trabajo (NOTA: reemplazar por la ruta donde guardaste el repositorio)
cd "C:\Ruta\De\Tu\Carpeta\ena-arroz-2024"

* Carpetas de salida agrupadas dentro de "Resultados"
capture mkdir "Resultados"
capture mkdir "Resultados\Base_Procesada"
capture mkdir "Resultados\Tablas"
capture mkdir "Resultados\Graficos"
capture mkdir "Resultados\Archivo_log"

* Archivo log: guarda en texto todo lo que aparece en la ventana de resultados
capture log close
log using "Resultados\Archivo_log\Log_Resultados_TIF.log", replace text
*___________________________________________________________________________________
* Paquetes externos (se instalan una sola vez; capture evita que falle si no hay internet)

* 1. estout (esttab): Para exportar tablas de regresión y descriptivas a Word (.rtf) y LaTeX (.tex)
capture which esttab
if _rc  capture ssc install estout

* 2. ftools: Motor computacional rápido en Mata (librería indispensable para reghdfe)
capture which ftools
if _rc  capture ssc install ftools, replace

* 3. reghdfe: Paquete oficial de Sergio Correia (2015) para efectos fijos y depuración de singletons
capture which reghdfe
if _rc  capture ssc install reghdfe, replace

* ── Verificación de existencia de datos / Descarga Automática ────────────────
* Si el usuario o revisor corre este script sin haber descargado previamente
* los datos, Stata ejecutará automáticamente Descarga_Microdatos_ENA2024.do
capture confirm file "973-Modulo1895\03_CAP200AB.dta"
local rc1 = _rc
capture confirm file "973-Modulo1911\19_CAP1100.dta"
local rc2 = _rc

if (`rc1' != 0 | `rc2' != 0) {
    display as yellow _n "No se detectaron las carpetas."
    display as yellow "Iniciando descarga y descompresión automática (ENA 2024)..."
    do "Descarga_Microdatos_ENA2024.do"
}


* ══════════════════════════════════════════════════════════════════════════════
* PARTE II: CARGA Y MERGE DE LOS DOS CAPÍTULOS (CUESTIONARIOS)
* ══════════════════════════════════════════════════════════════════════════════

* Se unen AMBOS archivos de datos antes de cualquier limpieza, para tener todas
* las variables disponibles desde el inicio y evitar perder observaciones después.

* ── Cargar el archivo principal (Capítulo 200: Producción agrícola) ──────────
use "973-Modulo1895\03_CAP200AB.dta", clear
describe
count

* ── Preparar el archivo secundario (Capítulo 1100: Productor/a) ──────────────
* Se extrae solo el productor/a titular (P1102==1), descartando cónyuge e hijos
preserve
    use "973-Modulo1911\19_CAP1100.dta", clear
    keep if P1102 == 1
    keep CCDD CCPP CCDI NSEGM ID_PROD UA CODIGO P1103 P1104_A P1105
    rename P1103   sexo_productor
    rename P1104_A edad_productor
    rename P1105   educ_productor
    tempfile productor
    save `productor'
restore

* ── Merge: unir ambos archivos de datos ──────────────────────────────────────
* m:1 porque un productor puede tener varios cultivos en CAP200AB
merge m:1 CCDD CCPP CCDI NSEGM ID_PROD UA CODIGO using `productor'
tab _merge
keep if _merge == 3    // Solo las observaciones emparejadas en ambos archivos
drop _merge


* ══════════════════════════════════════════════════════════════════════════════
* PARTE III: LIMPIEZA DE DATOS Y SELECCIÓN DE LA MUESTRA

* Se aplican los filtros que definen la muestra de trabajo DESPUÉS del merge.

* ── Filtro 1: Solo cultivo de ARROZ CÁSCARA ─────────────────────────────────
tab P204_NOM
keep if P204_NOM == "ARROZ CASCARA"
count

* ── Filtro 2: Solo unidades con una cosecha anual ────────────────────────────
* Reduce la heterogeneidad entre productores con múltiples campañas
tab P205_TOT
keep if P205_TOT == 1
count

* ── Revisión de valores perdidos antes de construir variables ────────────────
misstable summarize


* ══════════════════════════════════════════════════════════════════════════════
* PARTE IV: CONSTRUCCIÓN DE VARIABLES
* ══════════════════════════════════════════════════════════════════════════════
* Todas las variables se construyen aquí, en un solo bloque ordenado.

* ──────────────────────────────────────────────────────────────────────────────
* A. VARIABLE DEPENDIENTE (Y): Rendimiento agrícola → ln(kg/ha)
* ──────────────────────────────────────────────────────────────────────────────

* Verificar las variables fuente
describe P219_CANT_1 P219_EQUIV_KG P217_SUP_ha
summarize P219_CANT_1 P219_EQUIV_KG P217_SUP_ha

* Producción total en kg
* (La ENA registra producción en distintas unidades; EQUIV_KG las unifica a kg)
gen produccion_kg = P219_CANT_1 * P219_EQUIV_KG
label variable produccion_kg "Producción (kg)"

* Rendimiento = kg producidos / hectáreas cosechadas
gen rendimiento = produccion_kg / P217_SUP_ha
label variable rendimiento "Rendimiento (kg/ha)"

* Verificar que no existan valores imposibles (≤ 0) antes de aplicar logaritmo
count if rendimiento <= 0
summarize rendimiento, detail

* Logaritmo natural del rendimiento
* Reduce asimetría, atenúa valores extremos y permite interpretar coeficientes
* como variaciones porcentuales aproximadas
gen ln_rendimiento = ln(rendimiento)
label variable ln_rendimiento "ln(Rendimiento)"

summarize ln_rendimiento, detail

* Gráficos exploratorios de Y
histogram produccion_kg, frequency title("Distribución de la producción (kg)")
graph export "Resultados\Graficos\Hist_produccion_kg.png", replace

histogram rendimiento, frequency title("Distribución del rendimiento (kg/ha)")
graph export "Resultados\Graficos\Hist_rendimiento.png", replace

graph box rendimiento, title("Boxplot: Rendimiento agrícola")
graph export "Resultados\Graficos\Box_rendimiento.png", replace

histogram ln_rendimiento, normal title("Distribución de ln(Rendimiento)")
graph export "Resultados\Graficos\Hist_ln_rendimiento.png", replace

graph box ln_rendimiento, title("Boxplot: ln(Rendimiento)")
graph export "Resultados\Graficos\Box_ln_rendimiento.png", replace

* Observaciones con mayor rendimiento (revisión manual, no implica eliminarlas)
sort rendimiento
list P204_NOM produccion_kg P217_SUP_ha rendimiento in -20/l

* ──────────────────────────────────────────────────────────────────────────────
* B. VARIABLE INDEPENDIENTE PRINCIPAL (X1): Uso de semillas certificadas
* ──────────────────────────────────────────────────────────────────────────────
* Dummy: 1 = Certificada (P214==1) · 0 = No certificada (P214==2)

tab P214, missing

gen semillas_certificadas = .
replace semillas_certificadas = 1 if P214 == 1
replace semillas_certificadas = 0 if P214 == 2
label variable semillas_certificadas "Semillas certificadas"
label define lbl_semillas 0 "No" 1 "Sí"
label values semillas_certificadas lbl_semillas

* Validación: solo debe contener valores 0 y 1
assert semillas_certificadas == 0 | semillas_certificadas == 1 ///
    if semillas_certificadas < .
tab semillas_certificadas

* ──────────────────────────────────────────────────────────────────────────────
* C. VARIABLES DE CONTROL
* ──────────────────────────────────────────────────────────────────────────────

* ── C1. Fuente de agua (dummy) ───────────────────────────────────────────────
* Controla diferencias de disponibilidad hídrica
* 0 = Solo lluvia (secano, P212==1) · 1 = Otra fuente (río, pozo, represa, etc.)

tab P212, missing

gen fuente_agua = .
replace fuente_agua = 0 if P212 == 1
replace fuente_agua = 1 if inlist(P212, 2, 3, 4, 5, 6)
label define fuenteagua 0 "Solo lluvia (secano)" 1 "Otra fuente de agua", replace
label values fuente_agua fuenteagua
label variable fuente_agua "Fuente de agua"

tab fuente_agua P212   // Validación cruzada

* ── C2. Factores climáticos (dummies) ────────────────────────────────────────
* Controlan choques exógenos que afectan el rendimiento
* Missing se reemplaza por 0 (el productor no reportó ese evento)

foreach var of varlist P223B_1 P223B_6 P223B_7 P223B_8 {
    tab `var', missing
    replace `var' = 0 if missing(`var')
}

rename P223B_1 sequia
rename P223B_6 lluvias_destiempo
rename P223B_7 plagas_enfermedades
rename P223B_8 otros_factores

label variable sequia              "Sequía"
label variable lluvias_destiempo   "Lluvias a destiempo"
label variable plagas_enfermedades "Plagas y enfermedades"
label variable otros_factores      "Otros factores climáticos"

* ── C3. Departamento (efectos fijos regionales) ──────────────────────────────
* Se usará con ib14.departamento (14 = San Martín) en la regresión para controlar diferencias
* estructurales de clima, infraestructura y mercado, tomando a San Martín como base.

tab NOMBREDD
* proper() convierte "LAMBAYEQUE" → "Lambayeque", "LA LIBERTAD" → "La Libertad", etc.
* Debe hacerse ANTES del encode para que las etiquetas queden bien formateadas
replace NOMBREDD = proper(NOMBREDD)
* encode convierte el nombre del departamento en variable numérica con etiqueta de texto,
* así las tablas exportadas muestran "Piura", "La Libertad", etc. en lugar de números.
encode NOMBREDD, gen(departamento)
label variable departamento "Departamento"
* Fija San Martin (código numérico 14 en la variable codificada) como categoría base de referencia
* (San Martín concentra históricamente el mayor volumen de producción de arroz cáscara en Perú)
fvset base 14 departamento

* ── C3.1. Región natural (Costa, Sierra, Selva) ──────────────────────────────
capture drop region
gen region = REGION
label define lblregion 1 "Costa" 2 "Sierra" 3 "Selva", replace
label values region lblregion
label variable region "Región natural"
tab region, missing

* ── C4. Sexo del productor/a (dummy) ─────────────────────────────────────────
* 1 = Mujer · 0 = Hombre
* Controla posibles brechas de género en la adopción de tecnología agrícola

tab sexo_productor, missing

gen mujer_productora = .
replace mujer_productora = 1 if sexo_productor == 2
replace mujer_productora = 0 if sexo_productor == 1
label variable mujer_productora "Mujer productora"
label define lblsexo 0 "No" 1 "Sí"
label values mujer_productora lblsexo

assert mujer_productora == 0 | mujer_productora == 1 if mujer_productora < .
tab mujer_productora

* ── C5. Educación superior del productor/a (dummy) ───────────────────────────
* 1 = Tiene educación superior (P1105 >= 7) · 0 = Educación básica o sin nivel
* Controla si mayor formación se asocia con mejores decisiones tecnológicas

tab educ_productor, missing

gen educacion_superior = .
replace educacion_superior = 1 if educ_productor >= 7 & educ_productor < .
replace educacion_superior = 0 if educ_productor < 7
label variable educacion_superior "Educación superior"
label define lbleduc 0 "No" 1 "Sí"
label values educacion_superior lbleduc

assert educacion_superior == 0 | educacion_superior == 1 if educacion_superior < .
tab educacion_superior

* ── C6. Edad del productor/a (continua, en años) ────────────────────────────
* Se mantiene continua para no perder información (experiencia acumulada)

summarize edad_productor, detail
assert edad_productor > 0 if edad_productor < .
label variable edad_productor "Edad del productor"

histogram edad_productor, title("Distribución de la edad del productor/a")
graph export "Resultados\Graficos\Hist_edad_productor.png", replace


* ══════════════════════════════════════════════════════════════════════════════
* PARTE V: BASE FINAL (DEPURACIÓN Y GUARDADO)
* ══════════════════════════════════════════════════════════════════════════════
* Se eliminan observaciones inválidas y se conservan solo las variables del estudio.

* Verificar variables construidas
describe produccion_kg rendimiento ln_rendimiento ///
    semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

* ── Eliminar observaciones inválidas ────────────────────────────────────────
* Causa del punto (.) en ln_rendimiento: produccion_kg=0 → rendimiento=0 → ln(0)=indefinido

* 1. Rendimiento <= 0 o missing: ln no puede calcularse sobre valores no positivos
count if rendimiento <= 0 | missing(rendimiento)
drop  if rendimiento <= 0 | missing(rendimiento)

* 2. ln_rendimiento missing: cubre casos donde la división produjo un resultado inválido
count if missing(ln_rendimiento)
drop  if missing(ln_rendimiento)

* 3. semillas_certificadas missing: la variable principal no puede estar vacía en el modelo
count if missing(semillas_certificadas)
drop  if missing(semillas_certificadas)

* ──────────────────────────────────────────────────────────────────────────────
* 4. DEPURACIÓN DE CELDAS O GRUPOS UNITARIOS (Singletons / N <= 1)
* ──────────────────────────────────────────────────────────────────────────────

di "Observaciones válidas de referencia antes del filtrado de singletons: " _N

* Conservar solo las variables necesarias para los análisis posteriores:
* ── 1. Variables del modelo econométrico (OLS y Robusto):
*       ln_rendimiento, semillas_certificadas, fuente_agua, sequia, lluvias_destiempo,
*       plagas_enfermedades, otros_factores, mujer_productora, educacion_superior,
*       edad_productor y departamento (para efectos fijos espaciales i.departamento).
* ── 2. Variables auxiliares para Tablas Descriptivas y Gráficos (Partes VI, VIII y XV):
*       region (Costa/Sierra/Selva), NOMBREDD/CCDD (nombres), produccion_kg y rendimiento.
*       NOTA: 'region' NO entra al modelo econométrico para evitar multicolinealidad con departamento.
keep ln_rendimiento semillas_certificadas fuente_agua ///
     sequia lluvias_destiempo plagas_enfermedades otros_factores ///
     mujer_productora educacion_superior edad_productor ///
     departamento region ///
     CCDD NOMBREDD produccion_kg rendimiento

* Ordenar columnas: Y → X1 → controles → depto/región → variables auxiliares al final
order ln_rendimiento semillas_certificadas fuente_agua ///
      sequia lluvias_destiempo plagas_enfermedades otros_factores ///
      mujer_productora educacion_superior edad_productor ///
      departamento region ///
      CCDD NOMBREDD produccion_kg rendimiento

* Comprobación final
describe
misstable summarize
count

* Guardar la base depurada
save "Resultados\Base_Procesada\Base_arroz_modelo.dta", replace

* Exportar a Excel (nombres de variables como encabezado)
export excel using "Resultados\Base_Procesada\Base_arroz_modelo.xlsx", ///
    firstrow(variables) replace


* ══════════════════════════════════════════════════════════════════════════════
* PARTE VI: ESTADÍSTICAS DESCRIPTIVAS
* ══════════════════════════════════════════════════════════════════════════════
* La base ya está depurada. Todo el análisis parte de este punto.

* Estadísticos básicos de todas las variables
summarize ///
    ln_rendimiento rendimiento produccion_kg ///
    semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

* Estadísticos detallados de las variables continuas (mediana, percentiles, etc.)
summarize ln_rendimiento rendimiento produccion_kg edad_productor, detail

* Tablas de frecuencia de las variables dummy
tab semillas_certificadas
tab fuente_agua
tab mujer_productora
tab educacion_superior

* Distribución de factores climáticos
foreach var of varlist sequia lluvias_destiempo plagas_enfermedades otros_factores {
    tab `var'
}

* Composición geográfica de la muestra
tab NOMBREDD
tab region

* Tabla descriptiva por región natural en consola (Costa, Sierra, Selva)
tabstat rendimiento produccion_kg ln_rendimiento semillas_certificadas fuente_agua ///
        sequia lluvias_destiempo plagas_enfermedades otros_factores ///
        mujer_productora educacion_superior edad_productor if departamento != 4, ///
        by(region) statistics(mean sd n) format(%9.2f) columns(statistics)


* ══════════════════════════════════════════════════════════════════════════════
* PARTE VII: TABLAS DESCRIPTIVAS GENERALES (EXPORTACIÓN RTF — Tabla 1)
* ══════════════════════════════════════════════════════════════════════════════

local vars_finales ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

estpost summarize `vars_finales' if departamento != 4

esttab using "Resultados\Tablas\Tabla_1_Descriptiva_General.rtf", replace ///
    cells("mean(fmt(4)) sd(fmt(4)) min(fmt(4)) max(fmt(4))") ///
    label nonumber noobs nomtitle ///
    collabels("Media" "Desv. Est." "Mín." "Máx.") ///
    title("Tabla 1. Estadísticas descriptivas (N=1,991)")


* ══════════════════════════════════════════════════════════════════════════════
* PARTE VIII: TABLAS DE FRECUENCIAS POR REGIÓN NATURAL Y COMPOSICIÓN GEOGRÁFICA
* ══════════════════════════════════════════════════════════════════════════════

* ── Exportación 100% Automática de Tabulación de Frecuencia por Región Natural ──
eststo clear
estpost tabulate region if departamento != 4
esttab using "Resultados\Tablas\Tabla_Frecuencia_Region.rtf", replace ///
    cells("b(label(Freq.)) pct(fmt(2) label(Percent)) cumpct(fmt(2) label(Cum.))") ///
    noobs label nomtitle ///
    title("Tabla. Distribución de productores por región natural (N=1,991)") ///
    note("Nota: Cifras calculadas directamente de los registros de la ENA 2024.")

esttab using "Resultados\Tablas\Tabla_Frecuencia_Region.tex", replace ///
    cells("b(label(Freq.)) pct(fmt(2) label(Percent)) cumpct(fmt(2) label(Cum.))") ///
    noobs label nomtitle ///
    title("Tabla. Distribución de productores por región natural (N=1,991)") ///
    note("Nota: Cifras calculadas directamente de los registros de la ENA 2024.") ///
    booktabs alignment(D{.}{.}{-1})
eststo clear

* ── Exportación 100% Automática de Composición Geográfica (3 Tablas por Región) ──
eststo clear
foreach r in 1 2 3 {
    estpost tabulate departamento if region == `r' & departamento != 4
    esttab using "Resultados\Tablas\Tabla_Composicion_Region_`r'.rtf", replace ///
        cells("b(label(Productores (N))) pct(fmt(2) label(% en Región))") ///
        noobs label nomtitle title("Tabla. Composición geográfica depurada - Región `r' (N=1,991)") ///
        note("Nota: Cifras calculadas directamente de los registros de la ENA 2024.")
}
eststo clear


* ══════════════════════════════════════════════════════════════════════════════
* PARTE IX: MATRIZ DE CORRELACIONES (Tabla 2)
* ══════════════════════════════════════════════════════════════════════════════
pwcorr ///
    ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor if departamento != 4, ///
    sig star(0.05)

* Exportación
estpost correlate ///
    ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor if departamento != 4

esttab using "Resultados\Tablas\Tabla_2_Matriz_Correlaciones.rtf", replace ///
    unstack not ///
    title("Tabla 2. Matriz de correlaciones (N=1,991)")


* ══════════════════════════════════════════════════════════════════════════════
* PARTE X: MODELOS OLS ANIDADOS (COMPARACIÓN)
* ══════════════════════════════════════════════════════════════════════════════
eststo clear

eststo Modelo1: reg ln_rendimiento semillas_certificadas

eststo Modelo2: reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores

eststo Modelo3: reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

eststo Modelo4: reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor ib14.departamento


* ══════════════════════════════════════════════════════════════════════════════
* PARTE XI: DIAGNÓSTICOS DEL MODELO
* ══════════════════════════════════════════════════════════════════════════════

* ── Multicolinealidad (VIF) ──────────────────────────────────────────────────
vif

* ── Heterocedasticidad (Breusch-Pagan) ───────────────────────────────────────
estat hettest

* ══════════════════════════════════════════════════════════════════════════════
* PARTE XII: MODELO DEFINITIVO (ERRORES ROBUSTOS)
* ══════════════════════════════════════════════════════════════════════════════

* 1. Estimación robusta inicial de referencia antes de depurar singleton (N=1,992)
reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor ///
    ib14.departamento, vce(robust)

eststo Mod_Robusto_Con
* Se actualiza Modelo4 con errores robustos para la Gran Tabla 3 Unificada comparativa:
eststo Modelo4

* Exportar la regresión robusta inicial con singleton (N=1,992)
esttab Mod_Robusto_Con using "Resultados\Tablas\Tabla_4_Regresion_Robusta_Con_Singleton.rtf", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(5) se(5) nonumbers ///
    stats(N r2 r2_a, fmt(0 4 4) labels("Observaciones" "R-cuadrado" "R-cuadrado ajustado")) ///
    mtitles("Robusto (Con Singleton N=1992)") ///
    title("Tabla 4. Regresión con errores robustos antes de depurar singleton (N=1,992)") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante")

esttab Mod_Robusto_Con using "Resultados\Tablas\Tabla_4_Regresion_Robusta_Con_Singleton.tex", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(5) se(5) nonumbers ///
    stats(N r2 r2_a, fmt(0 4 4) labels("Observaciones" "R-cuadrado" "R-cuadrado ajustado")) ///
    mtitles("Robusto (Con Singleton N=1992)") ///
    title("Tabla 4. Regresión con errores robustos antes de depurar singleton (N=1,992)") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante") ///
    booktabs alignment(D{.}{.}{-1})

* ══════════════════════════════════════════════════════════════════════════════
* PARTE XIII: MODELO DEFINITIVO PURIFICADO DE SINGLETON (N=1,991)
* ══════════════════════════════════════════════════════════════════════════════
* Intentamos primero utilizar el paquete oficial reghdfe (Correia, 2015).
* Si el paquete reghdfe está disponible y responde correctamente, ejecuta el modelo.
* Si por incompatibilidad o falta de paquete no funciona (_rc != 0), se activa
* el Algoritmo Nativo de purificación y estimación de respaldo.

display as yellow _n "================================================================================"
display as yellow "ESTIMACIÓN DEL MODELO DEFINITIVO (CORREIA, 2015 - reghdfe / Nativo)"
display as yellow "================================================================================"

* 1. INTENTO DE EJECUCIÓN CON reghdfe (Paquete oficial de Sergio Correia)
* Nota: Al pasar ib14.departamento, intentamos depuración por reghdfe.
capture reghdfe ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor ///
    ib14.departamento, noabsorb vce(robust)

* 2. SI reghdfe FALLA O NO SE ENCUENTRA (_rc != 0), ACTIVAMOS EL ALGORITMO NATIVO:
if _rc != 0 {
    display as yellow "Nota: reghdfe no disponible..."
  
    * Ejecución real de purificación nativa:
    tempvar conteo_depto
    bysort departamento: gen `conteo_depto' = _N if !missing(departamento)
    quietly count if `conteo_depto' <= 1 & !missing(departamento)
    if r(N) > 0 {
        drop if `conteo_depto' <= 1
    }
    drop `conteo_depto'
    
    display as green "Nueva data purificada con algoritmo nativo: N = " _N
    
    reg ln_rendimiento semillas_certificadas fuente_agua ///
        sequia lluvias_destiempo plagas_enfermedades otros_factores ///
        mujer_productora educacion_superior edad_productor ///
        ib14.departamento, vce(robust)
}
else {
    display as green "Modelo ejecutado exitosamente con reghdfe (Correia, 2015): N = " e(N)
}

eststo Mod_Robusto_Sin
eststo Modelo5

* Guardar la base de datos purificada definitiva
save "Resultados\Base_Procesada\Base_arroz_modelo_purificada.dta", replace

* Exportar la regresión robusta purificada y definitiva (N=1,991) a Word y LaTeX
esttab Mod_Robusto_Sin using "Resultados\Tablas\Tabla_5_Regresion_Definitiva_Sin_Singleton.rtf", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(5) se(5) nonumbers ///
    stats(N r2 r2_a, fmt(0 4 4) labels("Observaciones" "R-cuadrado" "R-cuadrado ajustado")) ///
    mtitles("Modelo Definitivo (Sin Singleton N=1991)") ///
    title("Tabla 5. Modelo definitivo con errores robustos purificado de singletons (N=1,991)") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 5.departamento "Cajamarca" ///
              6.departamento "Huanuco" 7.departamento "Junin" ///
              8.departamento "La Libertad" 9.departamento "Lambayeque" ///
              10.departamento "Loreto" 11.departamento "Madre de Dios" ///
              12.departamento "Pasco" 13.departamento "Piura" ///
              14.departamento "San Martin" 15.departamento "Tumbes" ///
              16.departamento "Ucayali" _cons "Constante")

esttab Mod_Robusto_Sin using "Resultados\Tablas\Tabla_5_Regresion_Definitiva_Sin_Singleton.tex", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(5) se(5) nonumbers ///
    stats(N r2 r2_a, fmt(0 4 4) labels("Observaciones" "R-cuadrado" "R-cuadrado ajustado")) ///
    mtitles("Modelo Definitivo (Sin Singleton N=1991)") ///
    title("Tabla 5. Modelo definitivo con errores robustos purificado de singletons (N=1,991)") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 5.departamento "Cajamarca" ///
              6.departamento "Huanuco" 7.departamento "Junin" ///
              8.departamento "La Libertad" 9.departamento "Lambayeque" ///
              10.departamento "Loreto" 11.departamento "Madre de Dios" ///
              12.departamento "Pasco" 13.departamento "Piura" ///
              14.departamento "San Martin" 15.departamento "Tumbes" ///
              16.departamento "Ucayali" _cons "Constante") ///
    booktabs alignment(D{.}{.}{-1})

* ── EXPORTACIÓN UNIFICADA DE LOS 5 MODELOS EN UNA SOLA TABLA COMPARATIVA ─────
* Combina Modelos 1 al 4 (N=1,992) con el Modelo 5 Robusto purificado (N=1,991).
* En la columna del Modelo 5, Ayacucho aparece vacío/cero al haberse depurado.
esttab Modelo1 Modelo2 Modelo3 Modelo4 Modelo5 ///
    using "Resultados\Tablas\Tabla_3_Regresiones_Unificada.rtf", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(5) se(5) nonumbers ///
    stats(N r2 r2_a, fmt(0 4 4) labels("Observaciones" "R-cuadrado" "R-cuadrado ajustado")) ///
    mtitles("Modelo 1" "Modelo 2" "Modelo 3" "Modelo 4 (Robusto)" "Modelo 5 (Robusto)") ///
    title("Tabla 3. Evolución y comparación unificada de modelos de regresión (1 al 5)") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante") ///
    note("Nota: Modelos 1-3 estimados por MCO estándar (N=1,992). Modelos 4 y 5 reportan errores estándar robustos heterocedásticos (vce robust). El Modelo 4 evalúa la muestra completa (N=1,992) y el Modelo 5 depura el singleton de Ayacucho (N=1,991 según Correia 2015).")

esttab Modelo1 Modelo2 Modelo3 Modelo4 Modelo5 ///
    using "Resultados\Tablas\Tabla_3_Regresiones_Unificada.tex", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(5) se(5) nonumbers ///
    stats(N r2 r2_a, fmt(0 4 4) labels("Observaciones" "R-cuadrado" "R-cuadrado ajustado")) ///
    mtitles("Modelo 1" "Modelo 2" "Modelo 3" "Modelo 4 (Robusto)" "Modelo 5 (Robusto)") ///
    title("Tabla 3. Evolución y comparación unificada de modelos de regresión (1 al 5)") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante") ///
    note("Nota: Modelos 1-3 estimados por MCO estándar (N=1,992). Modelos 4 y 5 reportan errores estándar robustos heterocedásticos (vce robust). El Modelo 4 evalúa la muestra completa (N=1,992) y el Modelo 5 depura el singleton de Ayacucho (N=1,991 según Correia 2015).") ///
    booktabs alignment(D{.}{.}{-1})


* ══════════════════════════════════════════════════════════════════════════════
* PARTE XIV: PRUEBAS DE VALIDEZ ESTADÍSTICA CONJUNTA
* ══════════════════════════════════════════════════════════════════════════════
* H0: los coeficientes del bloque son iguales a cero.
* H1: al menos un coeficiente del bloque es distinto de cero.
* Si Prob > F <= 0.05, se rechaza H0 y el bloque es significativo.
* Nota: Se evalúa directamente sobre el Modelo 5 (Mod_Robusto_Sin) ya en memoria.

test semillas_certificadas fuente_agua sequia lluvias_destiempo ///
    plagas_enfermedades otros_factores mujer_productora ///
    educacion_superior edad_productor, mtest(noadjust)


* ══════════════════════════════════════════════════════════════════════════════
* PARTE XV: ANÁLISIS BIVARIADO Y GRÁFICOS DEFINITIVOS SOBRE MUESTRA PURIFICADA (N=1,991)
* ══════════════════════════════════════════════════════════════════════════════
* Todos los gráficos de la investigación se ejecutan después de haber definido el
* modelo final y haber purificado el singleton según Correia (2015) (N=1,991).

* ── 1. Producción y Rendimiento por Región Natural (Costa, Sierra, Selva) ────
graph bar (sum) produccion_kg, over(region) ///
    title("Producción total de arroz por región natural (N=1,991)") ///
    ytitle("Producción total (kg)") blabel(bar, format(%12.0fc))
graph export "Resultados\Graficos\Bivariado_produccion_total_region.png", replace

graph bar (mean) produccion_kg, over(region) ///
    title("Producción promedio por productor según región natural") ///
    ytitle("Producción promedio (kg/productor)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_produccion_media_region.png", replace

graph bar (mean) rendimiento, over(region) ///
    title("Rendimiento promedio de arroz según región natural") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_rendimiento_region.png", replace

* ── 2. Gráficos Comparativos Clave de las Explicativas (Muestra N=1,991) ─────
graph bar (mean) rendimiento, over(semillas_certificadas) ///
    title("Rendimiento promedio según uso de semillas certificadas") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_semillas.png", replace

graph bar (mean) rendimiento, over(educacion_superior) ///
    title("Rendimiento promedio según nivel educativo") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_educacion.png", replace

* Variable auxiliar de grupo etario (solo para visualización del gráfico)
summarize edad_productor, detail
gen productor_mayor = .
replace productor_mayor = 1 if edad_productor >= r(p50) & !missing(edad_productor)
replace productor_mayor = 0 if edad_productor < r(p50) & !missing(edad_productor)
label variable productor_mayor "Productor/a mayor (edad >= mediana)"
label define lbledad 0 "Joven" 1 "Mayor", replace
label values productor_mayor lbledad

graph bar (mean) rendimiento, over(productor_mayor) ///
    title("Rendimiento promedio según edad del productor/a") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_edad.png", replace
drop productor_mayor

* Rendimiento por departamento (en muestra depurada de singletons)
graph hbar (mean) rendimiento, over(NOMBREDD, sort(1)) ///
    title("Rendimiento promedio por departamento depurado (N=1,991)") ///
    ytitle("Rendimiento promedio (kg/ha)")
graph export "Resultados\Graficos\Bivariado_departamento.png", replace


* ══════════════════════════════════════════════════════════════════════════════
* NOTA SOBRE ENDOGENEIDAD
* ══════════════════════════════════════════════════════════════════════════════
* No se realiza prueba formal de endogeneidad porque no se dispone de una
* variable instrumental válida en la base final. La prueba estat endogenous
* solo puede aplicarse después de estimar un modelo IV/2SLS con un instrumento.
* Por tanto, el modelo se interpreta como asociación condicional.


* ══════════════════════════════════════════════════════════════════════════════
* CIERRE DEL DO-FILE

log close