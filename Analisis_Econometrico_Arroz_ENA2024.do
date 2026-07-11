/*================================================================================
  UNIVERSIDAD NACIONAL DE SAN AGUSTÍN DE AREQUIPA
  Facultad de Economía — Escuela Profesional de Economía
================================================================================
  TÍTULO:  Efecto del uso de semillas certificadas sobre el rendimiento
           agrícola del cultivo de arroz cáscara en las unidades
           agropecuarias del Perú (ENA, 2024)

  BASE:    Encuesta Nacional Agropecuaria (ENA) 2024

  CAPÍTULOS / ARCHIVOS DE DATOS UTILIZADOS (ENA 2024):
    • Capítulo 200 (Partes A y B) [03_CAP200AB.dta] → Producción y prácticas (Y, X1, riego, clima)
    • Capítulo 1100               [19_CAP1100.dta]  → Características del productor/a (sexo, edad, educ.)

  ESTRUCTURA DEL DO-FILE:
  ───────────────────────────────────────────────
   I.    Configuración inicial
   II.   Carga y merge de los dos capítulos (cuestionarios)
   III.  Limpieza de datos y selección de la muestra
   IV.   Construcción de variables
   V.    Base final (depuración y guardado)
   VI.   Estadísticas descriptivas
   VII.  Análisis bivariado (gráficos comparativos)
   VIII. Tablas descriptivas (exportación RTF)
   IX.   Matriz de correlaciones
   X.    Modelos OLS anidados (comparación)
   XI.   Diagnósticos del modelo
   XII.  Modelo definitivo (errores robustos)
   XIII. Pruebas de validez estadística conjunta
  ───────────────────────────────────────────────
================================================================================*/


* ══════════════════════════════════════════════════════════════════════════════
* PARTE I: CONFIGURACIÓN INICIAL
* ══════════════════════════════════════════════════════════════════════════════
* Se prepara un entorno limpio para garantizar la reproducibilidad del código.

clear all
set more off
capture log close
cls

* Directorio de trabajo (NOTA: cambiar según el equipo)
cd "PEGAR_AQUI_LA_RUTA_DE_TU_CARPETA"

* Carpetas de salida agrupadas dentro de "Resultados"
capture mkdir "Resultados"
capture mkdir "Resultados\Base_Procesada"
capture mkdir "Resultados\Tablas"
capture mkdir "Resultados\Graficos"
capture mkdir "Resultados\Archivo_log"

* Archivo log: guarda en texto todo lo que aparece en la ventana de resultados
capture log close
log using "Resultados\Archivo_log\Log_Resultados_TIF.log", replace text

* Paquetes externos (se instalan una sola vez; capture evita que falle sin internet)
capture which esttab
if _rc  capture ssc install estout     // Para tablas descriptivas y comparativas

capture which outreg2
if _rc  capture ssc install outreg2    // Para exportar regresiones a Word

* ── Verificación de existencia de datos / Descarga Automática ────────────────
* Si el usuario o revisor corre este script sin haber descargado previamente
* los datos, Stata ejecutará automáticamente Descarga_Microdatos_ENA2024.do
capture confirm file "973-Modulo1895\03_CAP200AB.dta"
local rc1 = _rc
capture confirm file "973-Modulo1911\19_CAP1100.dta"
local rc2 = _rc

if (`rc1' != 0 | `rc2' != 0) {
    display as yellow _n "No se detectaron las carpetas oficiales del INEI en el directorio."
    display as yellow "   Iniciando descarga y descompresión automática (ENA 2024)..."
    do "Descarga_Microdatos_ENA2024.do"
}


* ══════════════════════════════════════════════════════════════════════════════
* PARTE II: CARGA Y MERGE DE LOS DOS CAPÍTULOS (ARCHIVOS .DTA)
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
* ══════════════════════════════════════════════════════════════════════════════
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
label variable fuente_agua "Acceso a riego"

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

di "Observaciones válidas tras depuración: " _N

* Conservar solo las variables necesarias
* NOMBREDD  → variable de texto (solo referencia visual, no entra al modelo)
* departamento → variable numérica con etiquetas, usada con i.departamento en la regresión
* Se conservan ambas: NOMBREDD para saber el nombre del departamento al inspeccionar datos,
* y departamento para la regresión. CCDD se conserva como identificador original.
keep ln_rendimiento semillas_certificadas fuente_agua ///
     sequia lluvias_destiempo plagas_enfermedades otros_factores ///
     mujer_productora educacion_superior edad_productor ///
     departamento ///
     CCDD NOMBREDD produccion_kg rendimiento

* Ordenar columnas igual que la regresión: Y → X1 → controles → depto → resto al final
order ln_rendimiento semillas_certificadas fuente_agua ///
      sequia lluvias_destiempo plagas_enfermedades otros_factores ///
      mujer_productora educacion_superior edad_productor ///
      departamento ///
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


* ══════════════════════════════════════════════════════════════════════════════
* PARTE VII: ANÁLISIS BIVARIADO (GRÁFICOS COMPARATIVOS)
* ══════════════════════════════════════════════════════════════════════════════
* Comparaciones del rendimiento entre grupos, antes del modelo de regresión.

* Variable auxiliar de grupo etario (SOLO para gráficos, NO entra al modelo)
summarize edad_productor, detail
gen productor_mayor = .
replace productor_mayor = 1 if edad_productor >= r(p50) & edad_productor < .
replace productor_mayor = 0 if edad_productor < r(p50)
label variable productor_mayor "Productor/a mayor (edad >= mediana)"
label define lbledad 0 "Joven" 1 "Mayor"
label values productor_mayor lbledad

* Rendimiento según semillas certificadas (gráfico central de la investigación)
graph bar (mean) rendimiento, over(semillas_certificadas) ///
    title("Rendimiento promedio según uso de semillas certificadas") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_semillas.png", replace

* Rendimiento según nivel educativo
graph bar (mean) rendimiento, over(educacion_superior) ///
    title("Rendimiento promedio según nivel educativo") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_educacion.png", replace

* Rendimiento según grupo etario
graph bar (mean) rendimiento, over(productor_mayor) ///
    title("Rendimiento promedio según edad del productor/a") ///
    ytitle("Rendimiento promedio (kg/ha)") blabel(bar, format(%9.0f))
graph export "Resultados\Graficos\Bivariado_edad.png", replace

* Rendimiento por departamento (barras horizontales por la cantidad de categorías)
graph hbar (mean) rendimiento, over(NOMBREDD, sort(1)) ///
    title("Rendimiento promedio por departamento") ///
    ytitle("Rendimiento promedio (kg/ha)")
graph export "Resultados\Graficos\Bivariado_departamento.png", replace

drop productor_mayor   // Ya no se necesita; la edad continua va al modelo


* ══════════════════════════════════════════════════════════════════════════════
* PARTE VIII: TABLAS DESCRIPTIVAS (EXPORTACIÓN RTF — Tabla 1)
* ══════════════════════════════════════════════════════════════════════════════

estpost summarize ///
    ln_rendimiento rendimiento produccion_kg ///
    semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

esttab using "Resultados\Tablas\Tabla_1_Descriptiva_General.rtf", replace ///
    cells("count mean sd min max") label ///
    title("Tabla 1. Estadísticas descriptivas")


* ══════════════════════════════════════════════════════════════════════════════
* PARTE IX: MATRIZ DE CORRELACIONES (Tabla 2)
* ══════════════════════════════════════════════════════════════════════════════
* Identifica relaciones lineales preliminares y posible multicolinealidad
* (correlaciones > |0.80| entre explicativas merecen revisión con VIF).

pwcorr ///
    ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor, ///
    sig star(0.05)

* Exportación
estpost correlate ///
    ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

esttab using "Resultados\Tablas\Tabla_2_Matriz_Correlaciones.rtf", replace ///
    unstack not ///
    title("Tabla 2. Matriz de correlaciones")


* ══════════════════════════════════════════════════════════════════════════════
* PARTE X: MODELOS OLS ANIDADOS — Tabla comparativa (Tabla 3)
* ══════════════════════════════════════════════════════════════════════════════
* Se incorporan controles progresivamente para observar la estabilidad del
* coeficiente de semillas_certificadas. Si cambia mucho al agregar controles,
* hay indicios de sesgo por variables omitidas en los modelos más simples.

eststo clear

eststo Modelo1: reg ln_rendimiento ///
    semillas_certificadas

eststo Modelo2: reg ln_rendimiento ///
    semillas_certificadas ///
    fuente_agua

eststo Modelo3: reg ln_rendimiento ///
    semillas_certificadas ///
    fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores

eststo Modelo4: reg ln_rendimiento ///
    semillas_certificadas ///
    fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor

eststo Modelo5: reg ln_rendimiento ///
    semillas_certificadas ///
    fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor ///
    ib14.departamento

* Tabla comparativa exportada a Word (RTF) y LaTeX (.tex) con nombres exactos de departamentos
esttab Modelo1 Modelo2 Modelo3 Modelo4 Modelo5 ///
    using "Resultados\Tablas\Tabla_3_Regresiones.rtf", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) nonumbers ///
    mtitles("Modelo 1" "Modelo 2" "Modelo 3" "Modelo 4" "Modelo 5") ///
    title("Tabla 3. Resultados de las estimaciones") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante")

esttab Modelo1 Modelo2 Modelo3 Modelo4 Modelo5 ///
    using "Resultados\Tablas\Tabla_3_Regresiones.tex", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) nonumbers ///
    mtitles("Modelo 1" "Modelo 2" "Modelo 3" "Modelo 4" "Modelo 5") ///
    title("Tabla 3. Resultados de las estimaciones") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante")


* ══════════════════════════════════════════════════════════════════════════════
* PARTE XI: DIAGNÓSTICOS DEL MODELO COMPLETO (Modelo 5)
* ══════════════════════════════════════════════════════════════════════════════
* Se re-estima el Modelo 5 como base para las pruebas de diagnóstico.

reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor ///
    ib14.departamento

* ── Multicolinealidad (VIF) ──────────────────────────────────────────────────
* VIF < 5 → sin problema · 5–10 → moderado · ≥ 10 → grave
vif

* ── Heterocedasticidad (Breusch-Pagan) ───────────────────────────────────────
* H₀: varianza constante (homocedasticidad)
* H₁: varianza no constante (heterocedasticidad)
* Si p ≤ 0.05 → se rechaza H₀ → usar errores robustos en el modelo definitivo
estat hettest

* ══════════════════════════════════════════════════════════════════════════════
* PARTE XII: MODELO DEFINITIVO CON ERRORES ESTÁNDAR ROBUSTOS
* ══════════════════════════════════════════════════════════════════════════════
* vce(robust) corrige la heterocedasticidad detectada en la Parte XI,
* garantizando que los errores estándar y las pruebas t sean válidos.
* El efecto porcentual exacto de X1 es: (exp(β) - 1) × 100

reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia ///
    lluvias_destiempo ///
    plagas_enfermedades ///
    otros_factores ///
    mujer_productora ///
    educacion_superior ///
    edad_productor ///
    ib14.departamento, vce(robust)

* Exportar el modelo definitivo directamente con esttab a Word/RTF y LaTeX (.tex) con nombres exactos sin prefijos
eststo Modelo_Robusto

esttab Modelo_Robusto using "Resultados\Tablas\Modelo_Definitivo.rtf", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) nonumbers ///
    mtitles("Modelo definitivo") ///
    title("Tabla 4. Modelo definitivo con errores robustos") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante")

esttab Modelo_Robusto using "Resultados\Tablas\Modelo_Definitivo.tex", replace ///
    label star(* 0.10 ** 0.05 *** 0.01) b(4) se(4) nonumbers ///
    mtitles("Modelo definitivo") ///
    title("Tabla 4. Modelo definitivo con errores robustos") ///
    varlabels(1.departamento "Amazonas" 2.departamento "Ancash" ///
              3.departamento "Arequipa" 4.departamento "Ayacucho" ///
              5.departamento "Cajamarca" 6.departamento "Huanuco" ///
              7.departamento "Junin" 8.departamento "La Libertad" ///
              9.departamento "Lambayeque" 10.departamento "Loreto" ///
              11.departamento "Madre de Dios" 12.departamento "Pasco" ///
              13.departamento "Piura" 14.departamento "San Martin" ///
              15.departamento "Tumbes" 16.departamento "Ucayali" _cons "Constante")


* ══════════════════════════════════════════════════════════════════════════════
* PARTE XIII: PRUEBAS DE SIGNIFICANCIA CONJUNTA
* ══════════════════════════════════════════════════════════════════════════════
* H0: los coeficientes del bloque son iguales a cero.
* H1: al menos un coeficiente del bloque es distinto de cero.
* Si Prob > F <= 0.05, se rechaza H0 y el bloque es significativo.

quietly reg ln_rendimiento semillas_certificadas fuente_agua ///
    sequia lluvias_destiempo plagas_enfermedades otros_factores ///
    mujer_productora educacion_superior edad_productor ///
    ib14.departamento, vce(robust)

* Factores climáticos
test sequia lluvias_destiempo plagas_enfermedades otros_factores

* Características del productor/a
test mujer_productora educacion_superior edad_productor

* Efectos fijos departamentales
testparm i.departamento

* Significancia conjunta global
test semillas_certificadas fuente_agua sequia lluvias_destiempo ///
    plagas_enfermedades otros_factores mujer_productora ///
    educacion_superior edad_productor, mtest(noadjust)


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

