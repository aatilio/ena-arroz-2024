# 🌾 Efecto del Uso de Semillas Certificadas sobre el Rendimiento Agrícola del Arroz Cáscara en el Perú (ENA 2024)

![Stata](https://img.shields.io/badge/Stata-16.0%2B-1f5b8c?style=flat-square&logo=stata&logoColor=white)
![INEI](https://img.shields.io/badge/Datos-ENA_2024-e63946?style=flat-square)
![UNSA](https://img.shields.io/badge/UNSA-Economía-2b2d42?style=flat-square)
![Licencia](https://img.shields.io/badge/Licencia-Academic-success?style=flat-square)

> **Trabajo de Investigación de Fin de Curso (TIF) / Tesis**  
> **Universidad Nacional de San Agustín de Arequipa (UNSA)** — *Facultad de Economía*

---

## 📌 Resumen del Proyecto

Este repositorio contiene el paquete de replicación econométrica y análisis de microdatos para evaluar el impacto de adopción tecnológica (**semillas certificadas**) sobre la productividad agrícola ($kg/ha$) en el cultivo de **arroz cáscara** en el Perú. 

El estudio utiliza microdatos de la **Encuesta Nacional Agropecuaria (ENA) 2024**, ejecutada por el **Instituto Nacional de Estadística e Informática (INEI)**. A través de modelos de regresión por **Mínimos Cuadrados Ordinarios (OLS) anidados** y estimaciones con **errores estándar robustos de Huber-White**, se aísla el efecto de la semilla controlando por choques climatológicos, disponibilidad hídrica, ataques de plagas, capital humano del productor/a y efectos fijos departamentales.

---

## 📁 Estructura del Repositorio

El proyecto está diseñado bajo principios de **reproducción automatizada**. No se almacenan archivos pesados (`.dta` o `.zip`) gracias al script de descarga directa desde los servidores oficiales del gobierno.

```text
📦 ena2024-arroz-peru/
 ├── 📄 Analisis_Econometrico_Arroz_ENA2024.do   # Script principal de limpieza, merge, regresión y exportación
 ├── 📄 Descarga_Microdatos_ENA2024.do           # Script automatizado para descarga y descompresión (API INEI)
 ├── 📄 .gitignore                               # Ignora archivos pesados (.dta, .zip) para GitHub
 └── 📄 README.md                                # Documentación del proyecto
```

*(Una vez ejecutados los scripts, el sistema creará automáticamente la carpeta **`Resultados/`** donde se alojarán todas las tablas `.rtf/.tex`, gráficos `.png` y logs de auditoría).*

---

## 🚀 Guía Rápida de Replicación (3 Pasos)

Para replicar esta investigación desde cero en cualquier computadora con Stata instalado, **no es necesario descargar ni preparar bases de datos manualmente**:

### 1. Clonar o descargar este repositorio
Descarga este proyecto como ZIP o clónalo desde tu terminal:
```bash
git clone https://github.com/aatilio/ena2024-arroz-peru.git
```

### 2. Configurar tu ruta de trabajo en Stata
Abre Stata, ve al archivo `Analisis_Econometrico_Arroz_ENA2024.do` y coloca la ruta donde guardaste la carpeta en la línea de configuración:
```stata
cd "C:\Ruta\De\Tu\Carpeta\ena2024-arroz-peru"
```

### 3. ¡Ejecutar el script principal! (`Run`)
Presiona el botón **Run** (`Ctrl + D`) en `Analisis_Econometrico_Arroz_ENA2024.do`. El script funciona con un **Interruptor Inteligente**:
* Si es la primera vez que lo corres, llamará automáticamente a `Descarga_Microdatos_ENA2024.do`, conectará con los servidores del INEI (`proyectos.inei.gob.pe`), descargará los paquetes oficiales, extraerá los **Módulos 1895 y 1911** y correrá el modelo.
* Si ya tienes los datos descargados, el script se saltará la descarga y ejecutará las regresiones en menos de 3 segundos.

---

## 📊 Especificación del Modelo Econométrico

El modelo definitivo estimado toma la siguiente forma log-lineal:

$$\ln(\text{Rendimiento}_{i}) = \beta_0 + \beta_1 \text{SemillasCertificadas}_{i} + \mathbf{X}'_{i}\boldsymbol{\gamma} + \mathbf{Z}'_{i}\boldsymbol{\delta} + \mu_{d} + \varepsilon_{i}$$

Donde el cambio porcentual exacto sobre la productividad atribuible al uso de semilla certificada se calcula como: $(\exp(\hat{\beta}_1) - 1) \times 100$.

### Diccionario de Variables en la Regresión:

| Categoría | Variable | Tipo | Descripción |
| :--- | :--- | :--- | :--- |
| **Dependiente ($Y$)** | `ln_rendimiento` | Continua | Logaritmo natural del rendimiento agrícola ($kg/ha$). |
| **Tratamiento ($X_1$)** | `semillas_certificadas` | Dummy (0/1) | **1** = Utilizó semilla certificada en el cultivo de arroz. |
| **Prácticas y Clima** | `fuente_agua` | Dummy (0/1) | **1** = Cuenta con riego por gravedad, goteo o aspersión. |
| | `sequia` | Dummy (0/1) | **1** = Sufrió pérdidas por sequías en la campaña. |
| | `lluvias_destiempo` | Dummy (0/1) | **1** = Sufrió exceso de lluvias o inundaciones. |
| | `plagas_enfermedades` | Dummy (0/1) | **1** = Sufrió ataques severos de plagas o enfermedades. |
| | `otros_factores` | Dummy (0/1) | **1** = Sufrió heladas, granizadas o falta de crédito/mano de obra. |
| **Socioeconómicas** | `mujer_productora` | Dummy (0/1) | **1** = Productor/a agropecuario es mujer (`sexo_productor == 2`). |
| | `educacion_superior`| Dummy (0/1) | **1** = Productor/a cuenta con educación superior (técnica o universitaria). |
| | `edad_productor` | Continua | Edad en años cumplidos del productor/a titular. |
| **Efectos Fijos** | `ib14.departamento` | Categórica | Control por heterogeneidad geográfica no observada (16 regiones arroceras). Categoría base: **San Martín (14)**. |

---

## 📑 Archivos de Salida Generados (`Resultados/`)

Al finalizar la ejecución, se generarán los siguientes entregables automáticamente en tu carpeta de trabajo:

* 📄 **`Resultados/Tablas/Modelo_Definitivo.rtf / .tex`**: Tabla final con errores robustos lista para insertar directamente en **Microsoft Word** o **LaTeX** (con nombres de departamentos limpios sin numeración).
* 📄 **`Resultados/Tablas/Tabla_3_Regresiones.rtf / .tex`**: Tabla comparativa de los 5 modelos anidados.
* 📈 **`Resultados/Graficos/`**: Colección de histogramas de normalidad, boxplots de detección de outliers y gráficos de barras bivariados en `.png`.
* 💾 **`Resultados/Base_Procesada/Base_arroz_modelo.dta / .xlsx`**: Base de microdatos final depurada con etiquetas.

---

## 🏛️ Fuentes de Datos Oficiales
* **Microdatos ENA 2024 (INEI Perú):** [Portal de Proyectos y Microdatos del INEI (Encuesta 973)](https://proyectos.inei.gob.pe/microdatos/)
