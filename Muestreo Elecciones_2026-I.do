*********************************************************
* MUESTREO ALEATORIO SIMPLE DE ACTAS DE LIMA METROPOLITANA - ELECCIONES PRESIDENCIALES 2026 - PRIMERA VUELTA
/*******************************************************
* Autor: Kevin Aley Aparcana
* Fecha de elaboración: 2026-05-18
--------------------------------------------------------
* Base de datos:
	Nombre: Actas de Elecciones presidenciales 2026 - primera vuelta - Provincia de Lima, con fecha de corte al 2026-05-17
	Fuente: ONPE
	Recuperado de: https://resultadoelectoral.onpe.gob.pe/main/actas
--------------------------------------------------------
* Parámetros:
	Nivel de confianza: 95%
	Margen de error: 5%
	Varianza: p=0.5 (máxima)
	Estratos: 43 distritos
-------------------------------------------------------*/

* Configuración de la ruta de trabajo
*------------------------------------------------------*
clear all
set more off

global dir		"D:\MEGA\Publicaciones\1. Artículos\10. Elecciones - abril 2026"
global input	"$dir\1. Input"
global temp		"$dir\2. Temp"
global output	"$dir\3. Output"

* 1. Importar base de datos
*------------------------------------------------------*
import excel "$input\BD_actas_ONPE_2026_05_17.xlsx", sheet("Población") cellrange(A1) firstrow clear
	rename *, lower
	rename (elección Ámbito región) (eleccion ambito region)
save "$temp\BD_actas_ONPE.dta", replace

* 2. Cálculo del tamaño de muestra
*------------------------------------------------------*
use "$temp\BD_actas_ONPE.dta", clear

* Tamaño poblacional total
	count
	local N = r(N)
	display "Total de observaciones = " `N'

* Parámetros
	local Z = 1.96
	local e = 0.05
	local p = 0.5
	local q = 0.5

* Fórmula para población finita
local n_ = `=(`N'*(`Z'^2)*`p'*`q') / ((`e'^2)*(`N'-1) + (`Z'^2)*`p'*`q')'
display "Tamaño de muestra (sin redondear) = " `n_'

local n_red = ceil(`n_')
display "Tamaño de muestra (redondeado): " `n_red'

local n_sobr = 4
display "Tamaño de sobremuestra: " `n_sobr'

local n = ceil(`n_red') + `n_sobr'
display "Tamaño de muestra (redondeado y con sobremuestreo): " `n'

* 3. Seleccionar muestra
*------------------------------------------------------*

* Fijar semilla para reproducibilidad
set seed 777

* Generar número aleatorio uniforme
generate u = runiform()

* Ordenar aleatoriamente
sort u

* Seleccionar las primeras n observaciones
generate muestra = 0
replace muestra = 1 in 1/`n'

* Verificar tamaño de muestra
tab distrito muestra, m

* 4. Exportar resultado
*------------------------------------------------------*
export excel using "$output\Muestra_actas_ONPE_2026_05_17.xlsx" if muestra == 1, firstrow(variables) sheet("Muestra") replace
