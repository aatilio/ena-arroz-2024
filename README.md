# 🌾 Efecto del Uso de Semillas Certificadas sobre el Rendimiento Agrícola del Arroz Cáscara en el Perú: Evidencia del Año 2024

![Stata](https://img.shields.io/badge/Stata-16.0%2B-1f5b8c?style=flat-square&logo=stata&logoColor=white)
![INEI](https://img.shields.io/badge/Datos-ENA_2024-e63946?style=flat-square)
![UNSA](https://img.shields.io/badge/UNSA-Econometría_1-2b2d42?style=flat-square)
![LaTeX](https://img.shields.io/badge/Paper-LaTeX_10_Páginas-008080?style=flat-square&logo=latex)

> **Trabajo de Investigación de Fin de Curso — Econometría 1**  
> **Universidad Nacional de San Agustín de Arequipa (UNSA)** — *Facultad de Economía*  
> **Autores:** Ccanchi, A.; Condori, A.; Flores, M.; López, F.; Mamani, E.; Medina, C.; Morante, C.; Quispe, R.; Suri, D.; Villavicencio, S.; Yauri, G.

---

## 📌 Resumen y Motivación del Estudio

El arroz cáscara (*Oryza sativa* L.) es el cultivo de mayor trascendencia económica y seguridad alimentaria en el Perú, abarcando una vasta superficie cosechada en los valles de costa y selva. Sin embargo, la productividad agropecuaria nacional muestra una marcada heterogeneidad tecnológica, caracterizada por la persistencia del uso de grano autoguardado o reciclado frente a la adopción de insumos formales de alta pureza genética.

El presente estudio evalúa empíricamente el impacto del uso de **semillas certificadas** sobre el rendimiento físico en campo ($kg/ha$) durante la campaña agrícola 2024. Tomando como fundamento teórico y metodológico referencial el trabajo de **Takeshima et al. (2025)** para microdatos probabilísticos de encuestas agropecuarias nacionales (*General Household Survey-Panel* de Nigeria), nuestra investigación aísla el efecto marginal de la certificación formal frente a variedades comunes, controlando estrictamente por heterogeneidad en el acceso a riego, choques climáticos adversos, perfil sociodemográfico del productor y efectos fijos territoriales a nivel departamental.

---

## 🏛️ Estrategia Metodológica y Microdatos

### 1. Fuente de Datos y Depuración Muestral
La investigación utiliza microdatos probabilísticos representativos de la **Encuesta Nacional Agropecuaria (ENA) 2024**, ejecutada por el **Instituto Nacional de Estadística e Informática (INEI)** (Módulos 1895 y 1911). 
* La muestra analítica final consta de **$1{,}991$ unidades agropecuarias productoras de arroz cáscara** distribuidas en 16 departamentos agroecológicos.
* Siguiendo a **Correia (2015)**, se identificó y excluyó una observación solitaria (*singleton*) correspondiente al departamento de Ayacucho ($N=1$), lo cual evitó el sobreajuste artificial de interceptos, corrigo con exactitud los grados de libertad inferenciales y estabilizó el coeficiente de determinación en **$R^2 = 0{,}5480$**.

### 2. Especificación del Modelo Econométrico (MCO Robustos)
Estimamos una función de producción agropecuaria de forma **log-lineal** por Mínimos Cuadrados Ordinarios (MCO) con errores estándar robustos a heterocedasticidad de Huber-White (`vce(robust)`):

$$\ln(\text{Rendimiento}_{i}) = \beta_0 + \beta_1 \text{SemillasCertificadas}_{i} + \mathbf{X}'_{i}\boldsymbol{\gamma} + \mathbf{Z}'_{i}\boldsymbol{\delta} + \mu_{d} + \varepsilon_{i}$$

Donde el cambio porcentual exacto o aproximación directa sobre el rendimiento por hectárea atribuible a la adopción varietal y covariables continuas/binarias se evalúa mediante: $\hat{\beta}_k \times 100$.

---

## 📊 Principales Hallazgos Empíricos

Los resultados de las estimaciones (Modelo 5 definitivo, $F(23, 1967) = 76{,}32$, $p < 0{,}0001$) confirman y validan nuestra hipótesis general de investigación:

```text
========================================================================================
VARIABLE / DETERMINANTE          COEFICIENTE (β̂)    ERROR ROBUSTO   IMPACTO % DIRECTO
========================================================================================
[Tratamiento Principal]
Semillas Certificadas (1=Sí)       0.0982 ***          (0.0234)         +9.82 %
----------------------------------------------------------------------------------------
[Prácticas Agronómicas y Clima]
Fuente de Agua Tecnificada (1=Sí)  0.4858 ***          (0.0871)        +48.58 %
Choque: Sequía                     -0.0818 *           (0.0456)         -8.18 %
Choque: Lluvias a Destiempo        -0.1968 *           (0.1039)        -19.68 %
Choque: Plagas y Enfermedades      -0.1323 ***         (0.0270)        -13.23 %
Choque: Otros Factores Climáticos  -0.3629 ***         (0.0991)        -36.29 %
----------------------------------------------------------------------------------------
[Perfil Sociodemográfico]
Mujer Productora (1=Sí)            -0.0733 ***         (0.0253)         -7.33 %
Educación Superior (1=Sí)          0.0671 ***          (0.0258)         +6.71 %
Edad del Productor (años)          0.0001              (0.0006)         +0.01 % (Neutro)
========================================================================================
* p < 0.10, ** p < 0.05, *** p < 0.01
```

### 🧬 1. Retorno Marginal de la Semilla Certificada ($+9{,}82\,\%$)
El uso de semilla con certificación oficial ejerce un impacto positivo, directo y altamente significativo ($p < 0{,}001$, $t=4{,}19$), incrementando el rendimiento de arroz cáscara en **$+9{,}82\,\%$** frente al grano autoguardado o común. Desde la perspectiva agronómica y microeconómica, este diferencial responde a:
* **Superior pureza genética y varietal** sin degeneración por resiembra repetida.
* **Vigor fisiológico óptimo y germinación uniforme** del almácigo en parcela.
* **Alta sanidad del insumo** (ausencia de patógenos preexistentes transmitidos por semilla).

### 💧 2. Complementariedad con el Riego Tecnificado ($+48{,}58\,\%$)
El acceso a riego (por gravedad gestionada, aspersión o goteo) se consolida como el determinante individual que mayor impulso productivo otorga al cultivo (**$+48{,}58\,\%$**, $p < 0{,}001$). Esto corrobora que el retorno del germoplasma mejorado alcanza su máximo potencial bajo un suministro hídrico seguro.

### 🐛 3. Penalizaciones por Vulnerabilidad Agroclimática
Los choques exógenos y biológicos reducen drásticamente la cosecha arrocera: los ataques de **plagas y enfermedades** imponen una pérdida del **$-13{,}23\,\%$**, mientras que anomalías hídricas como **sequías** ($-8{,}18\,\%$), **lluvias a destiempo e inundaciones** ($-19{,}68\,\%$) y **otros desastres climáticos** ($-36{,}29\,\%$) impactan severamente en los pequeños productores.

### 🗺️ 4. Heterogeneidad Territorial (Efectos Fijos Departamentales)
Tomando como base comparativa a **San Martín (Base $= 0{,}00\,\%$)**, la estimación revela una marcada brecha de productividad regional:
* **Líderes productivos (Costa Norte y Sur):** Arequipa lidera el rendimiento nacional con **$+49{,}87\,\%$** ($p < 0{,}001$), seguido por Áncash (**$+44{,}36\,\%$**), La Libertad (**$+36{,}57\,\%$**), Cajamarca (**$+15{,}31\,\%$**) y Lambayeque (**$+9{,}75\,\%$**).
* **Brechas en Selva y Sierra:** Huánuco ($-20{,}49\,\%$), Loreto ($-22{,}90\,\%$), Ucayali ($-34{,}21\,\%$), Pasco ($-53{,}69\,\%$), Madre de Dios ($-62{,}04\,\%$) y Junín ($-84{,}28\,\%$) exhiben caídas estructurales, explicadas por limitadas condiciones de infraestructura e insumos agroquímicos en zonas de frontera agrícola.

---

## 🔍 Diagnóstico y Validación del Modelo

El modelo definitivo cumple con rigor las pruebas econométricas post-estimación:
1. **Multicolinealidad Ausente (VIF):** El Factor de Inflación de la Varianza medio es **$2{,}06$** (y apenas $1{,}39$ en la variable de semillas certificadas), muy por debajo del umbral crítico de $10$.
2. **Heterocedasticidad (Breusch-Pagan):** El test ($\chi^2 = 108{,}20$, $p < 0{,}0001$) rechaza la homocedasticidad, validando el uso obligatorio de estimadores de varianza robustos (`vce(robust)`).
3. **Estabilidad Paramétrica:** El parámetro de semilla se mantiene estable (de $0{,}2509$ en el Modelo 1 bivariado a $0{,}0982$ al incluir todos los controles agroecológicos, humanos y fijos), descartando sesgos graves por variable omitida.

---

## 💡 Discusión e Implicancias de Política Agraria

Nuestros resultados en el campo peruano son coherentes con la evidencia empírica internacional de **Takeshima et al. (2025)** en el *GHS-Panel* de Nigeria. En ambas economías en desarrollo, el aislamiento metodológico del atributo de *certificación formal* corrobora una rentabilidad marginal positiva y estadísticamente significativa en el rendimiento agrícola, supeditada al control territorial e hídrico.

**Recomendaciones de Política:**
1. **Focalización de Subsidios Temporales y Crédito Agrario:** Aliviar los costos de transacción y el diferencial de precio de la semilla certificada en pequeños agricultores donde el factor financiero representa una barrera de entrada al insumo formal.
2. **Inversión en Infraestructura de Riego Tecnificado:** Articular los programas de absorción varietal con el mejoramiento de canales y sistemas de riego para garantizar el retorno en productividad ($+48{,}58\,\%$).
3. **Fortalecimiento del Servicio de Extensión Agraria:** Capacitar al agricultor en buenas prácticas de manejo fitosanitario para mitigar las mermas por plagas ($-13{,}23\,\%$).

---

## 📦 Estructura de Replicación del Repositorio

```text
🌾 ena-arroz-2024/
 ├── 📄 Analisis_Econometrico_Arroz_ENA2024.do   # Script principal de limpieza, merge, regresión y exportación
 ├── 📄 Descarga_Microdatos_ENA2024.do           # Script automatizado para descarga de microdatos (API INEI)
 ├── 📂 Paper/                                   # Paquete LaTeX del artículo científico (main.tex / main_check.pdf)
 │    ├── 📄 main.tex                            # Código fuente del paper estilo journal (10 páginas exactas)
 │    └── 📄 main_check.pdf                      # PDF compilado final de la investigación
 ├── 📂 Resultados/                              # Directorio generado automáticamente con salidas del modelo
 │    ├── 📂 Tablas/                             # Tablas .rtf y .tex con los 5 modelos anidados y modelo definitivo
 │    ├── 📂 Graficos/                           # Histogramas, boxplots de outliers y barras en formato .png
 │    └── 📂 Base_Procesada/                     # Base final depurada lista para modelamiento (.dta / .xlsx)
 ├── 📄 .gitignore                               # Exclusión de archivos pesados de Stata (.dta, .zip)
 └── 📄 README.md                                # Documentación principal de la investigación
```

---

## 🚀 Guía de Replicación Automatizada en Stata (3 Pasos)

Para reproducir el $100\%$ de los cuadros, regresiones y gráficos de este estudio en Stata (**sin necesidad de descargar bases manualmente**):

### 1. Clonar este repositorio
```bash
git clone https://github.com/aatilio/ena-arroz-2024.git
```

### 2. Configurar la ruta de trabajo (`cd`)
Abre Stata, ve al script **`Analisis_Econometrico_Arroz_ENA2024.do`** y edita la línea de directorio para apuntar a la carpeta local de tu computadora:
```stata
cd "D:\UNSA\5 SEMESTER 2026-A\ECONOMETRICS 1\TIF\ena-arroz-2024"
```

### 3. Ejecutar el script principal (`Ctrl + D`)
Haz clic en **Run** en Stata. El do-file cuenta con un **Interruptor Inteligente (*Smart Switch*)**:
* Si no detecta las bases crudas del INEI en tu equipo, llamará automáticamente a `Descarga_Microdatos_ENA2024.do`, conectará con los servidores oficiales (`proyectos.inei.gob.pe`), descargará los **Módulos 1895 (ENA 973)** y **1911 (ENA 973)**, procesará los diccionarios y correrá las regresiones en un solo flujo.
* Si ya cuentas con los datos descargados, saltará el paso de red y ejecutará las estimaciones, pruebas diagnósticas y exportación de tablas en menos de 5 segundos.

---

## 📑 Referencias APA 7 Destacadas

* **Correia, S.** (2015). *Singletons, cluster-robust standard errors and fixed effects: A bad mix.* Technical Note, Duke University, 7(9), 1–7.
* **FAO & AfricaSeeds.** (2019). *The African Seed Sector: Towards a Master Plan for the Transformation of the African Seed Sector.* Food and Agriculture Organization of the United Nations.
* **INEI.** (2024). *Encuesta Nacional Agropecuaria (ENA) 2024: Módulos 1895 y 1911 - Microdatos abiertos.* Instituto Nacional de Estadística e Informática.
* **Takeshima, H., Edeh, H. O., & Ezenwa, O. L.** (2025). Certified seeds availability, use, yields and heterogeneity across agroecological and socioeconomic factors: Insights from nationally-representative farm panel data from Nigeria. *Agricultural Systems*, 223, 104192. https://doi.org/10.1016/j.agsy.2024.104192
