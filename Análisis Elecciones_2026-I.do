*********************************************************
* ANÁLISIS DE MUESTREA DE ACTAS DE LIMA METROPOLITANA - ELECCIONES PRESIDENCIALES 2026 - PRIMERA VUELTA
/*******************************************************
* Autor: Kevin Aley Aparcana
* Fecha de elaboración: 2026-05-20
--------------------------------------------------------
* Base de datos:
	Nombre: Muestra de actas de resultados de Elecciones presidenciales 2026 - primera vuelta - Provincia de Lima, con fecha de corte al 2026-05-17
	Fuente: ONPE
	Recuperado de: https://resultadoelectoral.onpe.gob.pe/main/actas
--------------------------------------------------------

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
import excel "$input\Muestra_actas_ONPE_resultados_2026_05_17.xlsx", sheet("Muestra") cellrange(A1) firstrow clear
	rename *, lower
	rename (electoreshábiles participaciónciudadana horadeinstalaciónacta) (electores_habil particip_ciud hora_instal)

* Limpieza de base de datos
	drop if hora_instal=="-"
* Crear variable de horas enteras
	gen horas_ent = real(substr(hora_instal, 1, strpos(hora_instal, ":")-1))
* Crear variable de minutos
	gen minutos = real(substr(hora_instal, strpos(hora_instal, ":")+1, .))
* Convertir variable de minutos en horas
	gen horas_resid = minutos/60
* Crear variable de hora de inicio de votación
	gen hora_inicio_vot = horas_ent + horas_resid
	replace hora_inicio_vot = 7  if hora_inicio_vot<7
	replace hora_inicio_vot = 14 if hora_inicio_vot>14
	hist hora_inicio_vot, freq addlabels ///
	xlabel(7(1)14)
	
	drop horas_ent minutos horas_resid

	format particip_ciud %6.4fc
	
save "$temp\Muestra_actas_ONPE_resultados_2026_05_17.dta", replace

* 2. Análisis estadístico gráfico
*------------------------------------------------------*
use "$temp\Muestra_actas_ONPE_resultados_2026_05_17.dta", clear

* Muestra
count

* Porcentaje de articipación ciudadana (muestral)
preserve
	collapse (sum) electores_habil totaldevotantes, ///
	by(ambito region provincia eleccion estadodelacta)
	gen porct_part=totaldevotantes/electores_habil
	table provincia, c(sum electores_habil sum totaldevotantes) format (%7.0fc)
	table provincia, c(sum porct_part) format (%7.5fc)
	* Nota: Porcentaje de articipación ciudadana (poblacional) = 80.034%
restore

* Hora promedio de inicio de votación
mean hora_inicio_vot
scalar prom_hora_inicio_vot = _b[hora_inicio_vot]
display prom_hora_inicio_vot

* Gráfico de dispersión con línea de regresión (correlación)
twoway ///
    (scatter particip_ciud hora_inicio_vot) ///
    (lfit particip_ciud hora_inicio_vot), ///
    title("Hora de inicio de votación vs. Participación ciudadana") ///
    xtitle("Hora de inicio de votación en la mesa de sufragio") ///
    ytitle("Porcentaje de participación ciudadana") ///
	xlabel(7 "7:00" 8 "8:00" 9 "9:00" 10 "10:00" 11 "11:00" 12 "12:00" 13 "13:00" 14 "14:00") ///
	ylabel(0.5 "50%" 0.6 "60%" 0.7 "70%" 0.8 "80%" 0.9 "90%" 1 "100%")

* Regresión
reg particip_ciud hora_inicio_vot
scalar beta_hora_inicio_vot = _b[hora_inicio_vot]
display beta_hora_inicio_vot

* Gráfico por horas
gen horas_ent = floor(hora_inicio_vot)
	label define horas_lbl 7 "7:00" 8 "8:00" 9 "9:00" 10 "10:00" 11 "11:00" 12 "12:00" 13 "13:00" 14 "14:00"
	label values horas_ent horas_lbl

graph bar ///
	(mean) prom_part=particip_ciud, over(horas_ent) ///
    title("Participación ciudadana (prom), según hora inicio votación") ///
	ytitle("Porcentaje de participación ciudadana") ///
	ylabel(0.2 "20%" 0.4 "40%" 0.6 "60%" 0.8 "80%" 1 "100%") ///
	blabel(bar, format(%4.2f) position(outside))

graph bar ///
	(count) n=particip_ciud, over(horas_ent) ///
    title("Número de participantes, según hora inicio votación") ///
	ytitle("Porcentaje de participación ciudadana") ///
	blabel(bar, format(%3.0f) position(outside))

* 3. Análisis de reducción de votantes (voto perdidos) por demoras en el inicio de votación
*------------------------------------------------------*
use "$temp\BD_actas_ONPE.dta", clear

* Reducción de votantes (votos perdidos) total

scalar sum_electores_habil = 7822555
	* Fuente: ONPE

scalar votos_perdidos_tot = sum_electores_habil * (prom_hora_inicio_vot-7) * -beta_hora_inicio_vot
display ceil(votos_perdidos_tot)

* Reducción de votantes (votos perdidos) por mesa

count
scalar num_mesas = r(N)
display num_mesas

scalar votos_perdidos_mesa = votos_perdidos_tot/num_mesas
display ceil(votos_perdidos_mesa)

* Reducción de votantes (votos perdidos) para mesa de 300 votantes según hora de inicio de votación

forvalue k = 7/14 {
scalar votos_perdidos_mesa_300v_`k'h = 300 * (`k'-7) * -beta_hora_inicio_vot
display votos_perdidos_mesa_300v_`k'h
display ceil(votos_perdidos_mesa_300v_`k'h)
}
