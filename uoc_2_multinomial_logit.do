*==============================================================================
* Master's thesis, Universitat Oberta de Catalunya (UOC), 2022 - Camila Aguirre Diaz
* Dynamics and structure of the Ecuadorian labour market, 2007-2019 (ENEMDU, INEC)
* Set the global below to your project folder. ENEMDU panel data are not included.
*==============================================================================
global dir "."   // change to your project folder
global data "$dir/DATA"
global res  "$dir/RESULTS"

************* MULTINOMIAL LOGIT **********************
* Requires SPost13 (mgen, listcoef): search spost13_ado
* and outreg: ssc install outreg
**** Escolaridad*******
cd "$data/Bases_mlogit"
     forval m=1/3{
	 use BDD`m', clear
	*Correr el modelo*
	local rlist "i.año_t i.sex_t edad i.estatc_t c.años_es_t##(i.sex_t i.etnia_t)" // este cambia para cada año por el año 
	quietly mlogit condactnt `rlist' [pw=fexpmatch], base(0) iter(200)
	*generar probabilidades ceteris paribus
    quietly mgen,  atmeans at(años_es_t=(0(1)23))  stub(escolaridad) replace
	label var escolaridadpr0 "Adecuado"
	label var escolaridadpr1 "Sub por tiempo"
	label var escolaridadpr2 "Sub por ingreso"
	label var escolaridadpr3 "Otro Inadec"
	label var escolaridadpr4 "No remunerado"
	label var escolaridadpr5 "Desempleo"
	label var escolaridadpr6 "PEI"
	
	local xlist escolaridadpr0 escolaridadpr1 escolaridadpr2 escolaridadpr3 escolaridadpr4 escolaridadpr5 escolaridadpr6
	
	*graficar
	graph twoway  (connected escolaridadpr0 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr1 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr2 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr3 escolaridadaños_es_t,msize(tiny) clwidth(medium)) (connected escolaridadpr4 escolaridadaños_es_t,msize(tiny) clwidth(medium)) (connected escolaridadpr5 escolaridadaños_es_t,msize(tiny) clwidth(medium))(connected escolaridadpr6 escolaridadaños_es_t,msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),title("Años de Escolaridad", size(medium)) ///
	 legend(size(small)) ytitle(Probabilidad) xtitle("años de escolaridad") xlab(0(2)24) ylab(0(0.1)0.7) legend(rows(3)) scheme (economist)
graph export "$res/Años_de_escolaridad/BDD`m'/escolaridad.png", as(png) replace

***Escolaridad por sexo***

forval x=0/1 {
quietly mgen if(sex_t==`x'), atmeans at(años_es_t=(0(1)23)) stub(sex`x') replace

}
forval u=0/6 {
label var sex1pr`u' "Hombre"
label var sex0pr`u' "Mujer"
}

graph twoway (connected sex1pr0 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr0 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de empleo adecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/adecxsex.png", as(png) replace

graph twoway (connected sex1pr1 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr1 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de sub por tiempo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/subtxsex.png", as(png) replace

graph twoway (connected sex1pr2 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr2 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de sub por ingresos) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/subixsex.png", as(png) replace

graph twoway (connected sex1pr3 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr3 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Otro empleo inadecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/otrixsex.png", as(png) replace

graph twoway (connected sex1pr4 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr4 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Empleo no remunerado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/norxsex.png", as(png) replace

graph twoway (connected sex1pr5 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr5 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Desempleo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/desxsex.png", as(png) replace

graph twoway (connected sex1pr6 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr6 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Inactividad) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/inaxsex.png", as(png) replace


*ESCOLARIDAD POR MINORIA*
forval x=0/1 {
quietly mgen if(etnia_t==`x'), atmeans at(años_es_t=(0(1)23)) stub(mino`x') replace

}
forval u=0/6 {
label var mino1pr`u' "Minoria"
label var mino0pr`u' "Blanco/Mestizo"
}

graph twoway (connected mino1pr0 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr0 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de empleo adecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/adecxmin.png", as(png) replace

graph twoway (connected mino1pr1 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr1 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de sub por tiempo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/subtxmin.png", as(png) replace

graph twoway (connected mino1pr2 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr2 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de sub por ingresos) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/subixmin.png", as(png) replace

graph twoway (connected mino1pr3 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr3 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Otro empleo inadecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/otrixmin.png", as(png) replace

graph twoway (connected mino1pr4 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr4 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Empleo no remunerado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/norxmin.png", as(png) replace

graph twoway (connected mino1pr5 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr5 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Desempleo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/descxmin.png", as(png) replace

graph twoway (connected mino1pr6 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr6 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Inactividad) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/inaxmin.png", as(png) replace

}


******************************************BDD4-5
forval m=4/5{
	 use BDD`m', clear
	*Correr el modelo*
	local tlist "i.año_t i.sex_t##i.estatc_t  edad i.etnia_t c.años_es_t##(i.sex_t i.etnia_t) i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `tlist' [pw=fexpmatch], base(0) iter(200)
	*generar probabilidades ceteris paribus
    quietly mgen,  atmeans at(años_es_t=(0(1)23))  stub(escolaridad) replace
	label var escolaridadpr0 "Adecuado"
	label var escolaridadpr1 "Sub por tiempo"
	label var escolaridadpr2 "Sub por ingreso"
	label var escolaridadpr3 "Otro Inadec"
	label var escolaridadpr4 "No remunerado"
	label var escolaridadpr5 "Desempleo"
	label var escolaridadpr6 "PEI"
	
	local xlist escolaridadpr0 escolaridadpr1 escolaridadpr2 escolaridadpr3 escolaridadpr4 escolaridadpr5 escolaridadpr6
	
	*graficar
	graph twoway  (connected escolaridadpr0 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr1 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr2 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr3 escolaridadaños_es_t,msize(tiny) clwidth(medium)) (connected escolaridadpr4 escolaridadaños_es_t,msize(tiny) clwidth(medium)) (connected escolaridadpr5 escolaridadaños_es_t,msize(tiny) clwidth(medium))(connected escolaridadpr6 escolaridadaños_es_t,msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),title("Años de Escolaridad", size(medium)) ///
	legend(size(small)) ytitle(Probabilidad) xtitle("años de escolaridad") xlab(0(2)24) ylab(0(0.1)0.7) legend(rows(3)) scheme (economist)
    graph export "$res/Años_de_escolaridad/BDD`m'/escolaridad.png", as(png) replace

***Escolaridad por sexo***
forval x=0/1 {
quietly mgen if(sex_t==`x'), atmeans at(años_es_t=(0(1)23)) stub(sex`x') replace

}
forval u=0/6 {
label var sex1pr`u' "Hombre"
label var sex0pr`u' "Mujer"
}

graph twoway (connected sex1pr0 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr0 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de empleo adecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/adecxsex.png", as(png) replace

graph twoway (connected sex1pr1 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr1 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de sub por tiempo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/subtxsex.png", as(png) replace

graph twoway (connected sex1pr2 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr2 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de sub por ingresos) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/subixsex.png", as(png) replace

graph twoway (connected sex1pr3 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr3 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Otro empleo inadecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/otrixsex.png", as(png) replace

graph twoway (connected sex1pr4 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr4 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Empleo no remunerado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/norxsex.png", as(png) replace

graph twoway (connected sex1pr5 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr5 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Desempleo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/desxsex.png", as(png) replace

graph twoway (connected sex1pr6 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr6 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Inactividad) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/inaxsex.png", as(png) replace


*ESCOLARIDAD POR MINORIA*
forval x=0/1 {
quietly mgen if(etnia_t==`x'), atmeans at(años_es_t=(0(1)23)) stub(mino`x') replace

}
forval u=0/6 {
label var mino1pr`u' "Minoria"
label var mino0pr`u' "Blanco/Mestizo"
}

graph twoway (connected mino1pr0 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr0 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de empleo adecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/adecxmin.png", as(png) replace

graph twoway (connected mino1pr1 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr1 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de sub por tiempo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/subtxmin.png", as(png) replace

graph twoway (connected mino1pr2 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr2 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de sub por ingresos) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/subixmin.png", as(png) replace

graph twoway (connected mino1pr3 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr3 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Otro empleo inadecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/otrixmin.png", as(png) replace

graph twoway (connected mino1pr4 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr4 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Empleo no remunerado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/norxmin.png", as(png) replace

graph twoway (connected mino1pr5 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr5 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Desempleo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/descxmin.png", as(png) replace

graph twoway (connected mino1pr6 mino0años_es_t, msize(tiny) clwidth(medium))(connected mino0pr6 mino0años_es_t,  msize(tiny) clwidth(medium) lcolor(green) mcolor(green)) ,  ytitle(Probabilidad de Inactividad) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist)
graph export "$res/Años_de_escolaridad/BDD`m'/inaxmin.png", as(png) replace

}


*************************************************BDD6

forval m=6/6{
	 use BDD`m', clear
	*Correr el modelo*
	local plist "i.año_t i.sex_t##(i.estatc_t  c.años_es_t) edad i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `plist' [pw=fexpmatch], base(0) iter(200)
	*generar probabilidades ceteris paribus
    quietly mgen,  atmeans at(años_es_t=(0(1)23))  stub(escolaridad) replace
	label var escolaridadpr0 "Adecuado"
	label var escolaridadpr1 "Sub por tiempo"
	label var escolaridadpr2 "Sub por ingreso"
	label var escolaridadpr3 "Otro Inadec"
	label var escolaridadpr4 "No remunerado"
	label var escolaridadpr5 "Desempleo"
	label var escolaridadpr6 "PEI"
	
	local xlist escolaridadpr0 escolaridadpr1 escolaridadpr2 escolaridadpr3 escolaridadpr4 escolaridadpr5 escolaridadpr6
	
	*graficar
	graph twoway  (connected escolaridadpr0 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr1 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr2 escolaridadaños_es_t, msize(tiny) clwidth(medium)) (connected escolaridadpr3 escolaridadaños_es_t,msize(tiny) clwidth(medium)) (connected escolaridadpr4 escolaridadaños_es_t,msize(tiny) clwidth(medium)) (connected escolaridadpr5 escolaridadaños_es_t,msize(tiny) clwidth(medium))(connected escolaridadpr6 escolaridadaños_es_t,msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),title("Años de Escolaridad", size(medium)) ///
	legend(size(small)) ytitle(Probabilidad) xtitle("años de escolaridad") xlab(0(2)24) ylab(0(0.1)0.7) legend(rows(3)) scheme (economist)
    graph export "$res/Años_de_escolaridad/BDD`m'/escolaridad.png", as(png) replace

***Escolaridad por sexo***
forval x=0/1 {
quietly mgen if(sex_t==`x'), atmeans at(años_es_t=(0(1)23)) stub(sex`x') replace

}
forval u=0/6 {
label var sex1pr`u' "Hombre"
label var sex0pr`u' "Mujer"
}

graph twoway (connected sex1pr0 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr0 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de empleo adecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/adecxsex.png", as(png) replace

graph twoway (connected sex1pr1 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr1 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de sub por tiempo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/subtxsex.png", as(png) replace

graph twoway (connected sex1pr2 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr2 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de sub por ingresos) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/subixsex.png", as(png) replace

graph twoway (connected sex1pr3 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr3 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Otro empleo inadecuado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/otrixsex.png", as(png) replace

graph twoway (connected sex1pr4 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr4 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Empleo no remunerado) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/norxsex.png", as(png) replace

graph twoway (connected sex1pr5 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr5 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Desempleo) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/desxsex.png", as(png) replace

graph twoway (connected sex1pr6 sex0años_es_t, msize(tiny) clwidth(medium)) (connected sex0pr6 sex0años_es_t, msize(tiny) clwidth(medium) lcolor(purple) mcolor(purple)),  ytitle(Probabilidad de Inactividad) xlab(0(2)24) ylab(0(0.1)0.6) scheme(economist) 
graph export "$res/Años_de_escolaridad/BDD`m'/inaxsex.png", as(png) replace

}

*************************************Margins******
**BDD 1-3*
cd "$data/Bases_mlogit"
forval m=1/3{
	 use BDD`m', clear
	*Correr el modelo*
	local rlist "i.año_t i.sex_t edad i.estatc_t c.años_es_t##(i.sex_t i.etnia_t)" // este cambia para cada año por el año 
	quietly mlogit condactnt `rlist' [pw=fexpmatch], base(0) iter(200)
	margins i.año_t i.estatc_t, at(sex_t==1 etnia_t==1 (means) años_es_t edad) dydx(*) post
	outreg using "$res/margins1_3.doc", merge replace
}

  clear 
  cls
   outreg, clear
** BDD 4-5
forval m=4/5{
	 use BDD`m', clear
	*Correr el modelo*
	local tlist "i.año_t i.sex_t##i.estatc_t  edad i.etnia_t c.años_es_t##(i.sex_t i.etnia_t) i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `tlist' [pw=fexpmatch], base(0) iter(200)
	outreg using  "$res/margins4_5.doc", merge replace	
}
   clear 
   cls
****BDD6
forval m=6/6{
	 use BDD`m', clear
	*Correr el modelo*
	local plist "i.año_t i.sex_t##(i.estatc_t  c.años_es_t) edad i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `plist' [pw=fexpmatch], base(0) iter(200)
	outreg using "$res/margins6.doc", merge replace	
}
******************************************************************LOGITS PARA ODDS RATIOS*************************************************************************
***BDD 1-3*
cd "$data/Bases_mlogit"
forval m=1/3{
	 use BDD`m', clear
	*Correr el modelo*
	local rlist "i.año_t i.sex_t##i.estatc_t edad c.años_es_t##(i.sex_t i.etnia_t)" // este cambia para cada año por el año 
	quietly mlogit condactnt `rlist' [pw=fexpmatch], base(0) iter(200)
	di in red "BDD`m'"
	listcoef
}
 
     clear
	 cls
*** BDD4-5 
set matsize 1000	 
forval m=4/5{
	 use BDD`m', clear
	*Correr el modelo*
	local tlist "i.año_t i.sex_t##i.estatc_t  edad i.etnia_t c.años_es_t##(i.sex_t i.etnia_t) i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `tlist' [pw=fexpmatch], base(0) iter(200)
	di in red "BDD`m'"
	listcoef
}
     
	 clear
	 cls
	 
	 *** BDD6
set matsize 1000	
forval m=6/6 {
	 use BDD`m', clear
	*Correr el modelo*
	local plist "i.año_t i.sex_t##(i.estatc_t  c.años_es_t) edad i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `plist' [pw=fexpmatch], base(0) iter(200)
    di in red "BDD`m'"
	listcoef
}

	****************GRAFICOS Otros ***********************************
	*** estado civil
   cd "$data/Bases_mlogit"
   forval m=1/3{
	 use BDD`m', clear
	*Correr el modelo*
	local rlist "i.año_t i.sex_t edad i.estatc_t c.años_es_t##(i.sex_t i.etnia_t)" // este cambia para cada año por el año 
	quietly mlogit condactnt `rlist' [pw=fexpmatch], base(0) iter(200)
	**Margins para hombre 
	**Con pareja 
	quietly mgen, atmeans at(estatc_t=1 sex_t=1) stub(homcon) replace
	label var homconpr0 "Hombre con Pareja"
	label var homconpr1 "Hombre con Pareja"
	label var homconpr2 "Hombre con Pareja"
	label var homconpr3 "Hombre con Pareja"
	label var homconpr4 "Hombre con Pareja"
	label var homconpr5 "Hombre con Pareja"
	label var homconpr6 "Hombre con Pareja"
	*Sin Pareja
	quietly mgen, atmeans at(estatc_t=0 sex_t=1) stub(homsin) replace
	label var homsinpr0 "Hombre sin Pareja"
	label var homsinpr1 "Hombre sin Pareja"
	label var homsinpr2 "Hombre sin Pareja"
	label var homsinpr3 "Hombre sin Pareja"
	label var homsinpr4 "Hombre sin Pareja"
	label var homsinpr5 "Hombre sin Pareja"
	label var homsinpr6 "Hombre sin Pareja"
	*Margins para Mujeres
	*Con pareja
	quietly mgen, atmeans at(estatc_t=1 sex_t=0) stub(mujcon) replace
	label var mujconpr0 "Mujer con Pareja"
	label var mujconpr1 "Mujer con Pareja"
	label var mujconpr2 "Mujer con Pareja"
	label var mujconpr3 "Mujer con Pareja"
	label var mujconpr4 "Mujer con Pareja"
	label var mujconpr5 "Mujer con Pareja"
	label var mujconpr6 "Mujer con Pareja"
	*Sin pareja
	quietly mgen, atmeans at(estatc_t=0 sex_t=0) stub(mujsin) replace
	label var mujsinpr0 "Mujer sin Pareja"
	label var mujsinpr1 "Mujer sin Pareja"
	label var mujsinpr2 "Mujer sin Pareja"
	label var mujsinpr3 "Mujer sin Pareja"
	label var mujsinpr4 "Mujer sin Pareja"
	label var mujsinpr5 "Mujer sin Pareja"
	label var mujsinpr6 "Mujer sin Pareja"
	
	
drop if homconpr1==.

save "$res/Resto_variables/BDD`m'.dta", replace

}

clear 

forval m=4/5{
	 use BDD`m', clear
	*Correr el modelo*
	local rlist "i.año_t i.sex_t edad i.estatc_t c.años_es_t##(i.sex_t i.etnia_t)" // este cambia para cada año por el año 
	quietly mlogit condactnt `rlist' [pw=fexpmatch], base(0) iter(200)
	**Margins para hombre 
	**Con pareja 
	quietly mgen, atmeans at(estatc_t=1 sex_t=1) stub(homcon) replace
	label var homconpr0 "Hombre con Pareja"
	label var homconpr1 "Hombre con Pareja"
	label var homconpr2 "Hombre con Pareja"
	label var homconpr3 "Hombre con Pareja"
	label var homconpr4 "Hombre con Pareja"
	label var homconpr5 "Hombre con Pareja"
	label var homconpr6 "Hombre con Pareja"
	*Sin Pareja
	quietly mgen, atmeans at(estatc_t=0 sex_t=1) stub(homsin) replace
	label var homsinpr0 "Hombre sin Pareja"
	label var homsinpr1 "Hombre sin Pareja"
	label var homsinpr2 "Hombre sin Pareja"
	label var homsinpr3 "Hombre sin Pareja"
	label var homsinpr4 "Hombre sin Pareja"
	label var homsinpr5 "Hombre sin Pareja"
	label var homsinpr6 "Hombre sin Pareja"
	*Margins para Mujeres
	*Con pareja
	quietly mgen, atmeans at(estatc_t=1 sex_t=0) stub(mujcon) replace
	label var mujconpr0 "Mujer con Pareja"
	label var mujconpr1 "Mujer con Pareja"
	label var mujconpr2 "Mujer con Pareja"
	label var mujconpr3 "Mujer con Pareja"
	label var mujconpr4 "Mujer con Pareja"
	label var mujconpr5 "Mujer con Pareja"
	label var mujconpr6 "Mujer con Pareja"
	*Sin pareja
	quietly mgen, atmeans at(estatc_t=0 sex_t=0) stub(mujsin) replace
	label var mujsinpr0 "Mujer sin Pareja"
	label var mujsinpr1 "Mujer sin Pareja"
	label var mujsinpr2 "Mujer sin Pareja"
	label var mujsinpr3 "Mujer sin Pareja"
	label var mujsinpr4 "Mujer sin Pareja"
	label var mujsinpr5 "Mujer sin Pareja"
	label var mujsinpr6 "Mujer sin Pareja"
	
	
drop if homconpr1==.

save "$res/Resto_variables/BDD`m'.dta", replace

}

forval m=6/6{
	 use BDD`m', clear
	*Correr el modelo*
	local plist "i.año_t i.sex_t##(i.estatc_t  c.años_es_t) edad i.area"  // este cambia para cada año por el año 
	quietly mlogit condactnt `plist' [pw=fexpmatch], base(0) iter(200)
	**Margins para hombre 
	**Con pareja 
	quietly mgen, atmeans at(estatc_t=1 sex_t=1) stub(homcon) replace
	label var homconpr0 "Hombre con Pareja"
	label var homconpr1 "Hombre con Pareja"
	label var homconpr2 "Hombre con Pareja"
	label var homconpr3 "Hombre con Pareja"
	label var homconpr4 "Hombre con Pareja"
	label var homconpr5 "Hombre con Pareja"
	label var homconpr6 "Hombre con Pareja"
	*Sin Pareja
	quietly mgen, atmeans at(estatc_t=0 sex_t=1) stub(homsin) replace
	label var homsinpr0 "Hombre sin Pareja"
	label var homsinpr1 "Hombre sin Pareja"
	label var homsinpr2 "Hombre sin Pareja"
	label var homsinpr3 "Hombre sin Pareja"
	label var homsinpr4 "Hombre sin Pareja"
	label var homsinpr5 "Hombre sin Pareja"
	label var homsinpr6 "Hombre sin Pareja"
	*Margins para Mujeres
	*Con pareja
	quietly mgen, atmeans at(estatc_t=1 sex_t=0) stub(mujcon) replace
	label var mujconpr0 "Mujer con Pareja"
	label var mujconpr1 "Mujer con Pareja"
	label var mujconpr2 "Mujer con Pareja"
	label var mujconpr3 "Mujer con Pareja"
	label var mujconpr4 "Mujer con Pareja"
	label var mujconpr5 "Mujer con Pareja"
	label var mujconpr6 "Mujer con Pareja"
	*Sin pareja
	quietly mgen, atmeans at(estatc_t=0 sex_t=0) stub(mujsin) replace
	label var mujsinpr0 "Mujer sin Pareja"
	label var mujsinpr1 "Mujer sin Pareja"
	label var mujsinpr2 "Mujer sin Pareja"
	label var mujsinpr3 "Mujer sin Pareja"
	label var mujsinpr4 "Mujer sin Pareja"
	label var mujsinpr5 "Mujer sin Pareja"
	label var mujsinpr6 "Mujer sin Pareja"
	
	
drop if homconpr1==.

save "$res/Resto_variables/BDD`m'.dta", replace

}



clear all 
cd "$res/Resto_variables"
use BDD1

merge m:m homconpr0 homconpr1 homconpr2 homconpr3 homconpr4 homconpr5 homconpr6 homsinpr0 homsinpr1 homsinpr2 homsinpr3 homsinpr4 homsinpr5 homsinpr6 mujconpr0 mujconpr1 mujconpr2 mujconpr3 mujconpr4 mujconpr5 mujconpr6 mujsinpr0 mujsinpr1 mujsinpr2 mujsinpr3 mujsinpr4 mujsinpr5 mujsinpr6 using BDD2, nogen
merge m:m homconpr0 homconpr1 homconpr2 homconpr3 homconpr4 homconpr5 homconpr6 homsinpr0 homsinpr1 homsinpr2 homsinpr3 homsinpr4 homsinpr5 homsinpr6 mujconpr0 mujconpr1 mujconpr2 mujconpr3 mujconpr4 mujconpr5 mujconpr6 mujsinpr0 mujsinpr1 mujsinpr2 mujsinpr3 mujsinpr4 mujsinpr5 mujsinpr6 using BDD3, nogen
merge m:m homconpr0 homconpr1 homconpr2 homconpr3 homconpr4 homconpr5 homconpr6 homsinpr0 homsinpr1 homsinpr2 homsinpr3 homsinpr4 homsinpr5 homsinpr6 mujconpr0 mujconpr1 mujconpr2 mujconpr3 mujconpr4 mujconpr5 mujconpr6 mujsinpr0 mujsinpr1 mujsinpr2 mujsinpr3 mujsinpr4 mujsinpr5 mujsinpr6 using BDD4, nogen
merge m:m homconpr0 homconpr1 homconpr2 homconpr3 homconpr4 homconpr5 homconpr6 homsinpr0 homsinpr1 homsinpr2 homsinpr3 homsinpr4 homsinpr5 homsinpr6 mujconpr0 mujconpr1 mujconpr2 mujconpr3 mujconpr4 mujconpr5 mujconpr6 mujsinpr0 mujsinpr1 mujsinpr2 mujsinpr3 mujsinpr4 mujsinpr5 mujsinpr6 using BDD5, nogen
merge m:m homconpr0 homconpr1 homconpr2 homconpr3 homconpr4 homconpr5 homconpr6 homsinpr0 homsinpr1 homsinpr2 homsinpr3 homsinpr4 homsinpr5 homsinpr6 mujconpr0 mujconpr1 mujconpr2 mujconpr3 mujconpr4 mujconpr5 mujconpr6 mujsinpr0 mujsinpr1 mujsinpr2 mujsinpr3 mujsinpr4 mujsinpr5 mujsinpr6 using BDD6, nogen

gen periodo=_n
label define periodo_lbl 1"2007-2008" 2"2009-2010" 3"2011-2012" 4"2013-2014" 5"2015-2016" 6"2018-2019"
label value periodo periodo_lbl

forval x=0/6 {
graph twoway dot homconpr`x' homsinpr`x' mujconpr`x' mujsinpr`x' periodo, xlabel(, valuelabel angle(45))  xtitle("") ytitle(Probabilidad) msize(large large large large) scheme(vg_s1c)
graph export "$res/Resto_variables/graficos/Categoria`x'.png", as(png) replace
}


gr combine Categoria0.gph Categoria1.gph //revisar no sale

*************edad 

cd "$data/Bases_mlogit"
     forval m=1/3{
	 use BDD`m', clear
	*Correr el modelo*
	local rlist "i.año_t i.sex_t edad i.estatc_t i.etnia_t c.años_es_t##(i.sex_t i.etnia_t)" // este cambia para cada año por el año 
	quietly mlogit condactnt `rlist' [pw=fexpmatch], base(0) iter(200)
	*generar probabilidades ceteris paribus
    quietly mgen,  atmeans at(edad=(0(1)98))  stub(edad) replace
	label var edadpr0 "Adecuado"
	label var edadpr1 "Sub por tiempo"
	label var edadpr2 "Sub por ingreso"
	label var edadpr3 "Otro Inadec"
	label var edadpr4 "No remunerado"
	label var edadpr5 "Desempleo"
	label var edadpr6 "PEI"
	
	local xlist  edadpr0 edadpr1 edadpr3 edadpr4 edadpr5 edadpr6 
	
	*graficar
	graph twoway  (line edadpr0 edadedad if edadedad>=15 , msize(tiny) clwidth(thick)) (line edadpr1 edadedad if edadedad>=15, msize(tiny) clwidth(thick)) (line edadpr2 edadedad if edadedad>=15, msize(tiny) clwidth(thick)) (line edadpr3 edadedad if edadedad>=15,msize(tiny) clwidth(thick)) (line edadpr4 edadedad if edadedad>=15,msize(tiny) clwidth(thick)) (line edadpr5 edadedad if edadedad>=15,msize(tiny) clwidth(thick))(line edadpr6 edadedad if edadedad>=15,msize(tiny) clwidth(thick) lcolor(purple) mcolor(purple)),title("Edad", size(medium)) ///
	 legend(size(small)) ytitle(Probabilidad) xtitle("edad") xlab(15(10)100) ylab(0(0.1)0.6) legend(rows(3)) scheme (economist)
	 graph export "$res/Edad/BDD`m'/Edad.png",as(png) replace
	
	}
	

	forval m=4/5{
	 use BDD`m', clear
	*Correr el modelo*
    local tlist "i.Año i.Sexo##i.ESTCIV Edad  i.minoria c.escol##(i.Sexo i.minoria) i.area"
	quietly mlogit condactnt `tlist' [pw=fexpmatch], base(0) iter(200)
	*generar probabilidades ceteris paribus
    quietly mgen,  atmeans at(edad=(0(1)98))  stub(edad) replace
	label var edadpr0 "Adecuado"
	label var edadpr1 "Sub por tiempo"
	label var edadpr2 "Sub por ingreso"
	label var edadpr3 "Otro Inadec"
	label var edadpr4 "No remunerado"
	label var edadpr5 "Desempleo"
	label var edadpr6 "PEI"
	
	local xlist  edadpr0 edadpr1 edadpr3 edadpr4 edadpr5 edadpr6 
	
	*graficar
	graph twoway  (line edadpr0 edadedad if edadedad>=15 , msize(tiny) clwidth(thick)) (line edadpr1 edadedad if edadedad>=15, msize(tiny) clwidth(thick)) (line edadpr2 edadedad if edadedad>=15, msize(tiny) clwidth(thick)) (line edadpr3 edadedad if edadedad>=15,msize(tiny) clwidth(thick)) (line edadpr4 edadedad if edadedad>=15,msize(tiny) clwidth(thick)) (line edadpr5 edadedad if edadedad>=15,msize(tiny) clwidth(thick))(line edadpr6 edadedad if edadedad>=15,msize(tiny) clwidth(thick) lcolor(purple) mcolor(purple)),title("Edad", size(medium)) ///
	 legend(size(small)) ytitle(Probabilidad) xtitle("edad") xlab(15(10)100) ylab(0(0.1)0.6) legend(rows(3)) scheme (economist)
	 graph export "$res/Edad/BDD`m'/Edad.png",as(png) replace
	
	}
	
	forval m=6/6{
	 use BDD`m', clear
	*Correr el modelo*
	local plist "i.año_t i.sex_t##(i.estatc_t  c.años_es_t) edad i.area" // este cambia para cada año por el año 
	quietly mlogit condactnt `plist' [pw=fexpmatch], base(0) iter(200)
	*generar probabilidades ceteris paribus
    quietly mgen,  atmeans at(edad=(0(1)98))  stub(edad) replace
	label var edadpr0 "Adecuado"
	label var edadpr1 "Sub por tiempo"
	label var edadpr2 "Sub por ingreso"
	label var edadpr3 "Otro Inadec"
	label var edadpr4 "No remunerado"
	label var edadpr5 "Desempleo"
	label var edadpr6 "PEI"
	
	local xlist  edadpr0 edadpr1 edadpr3 edadpr4 edadpr5 edadpr6 
	
	*graficar
	graph twoway  (line edadpr0 edadedad if edadedad>=15 , msize(tiny) clwidth(thick)) (line edadpr1 edadedad if edadedad>=15, msize(tiny) clwidth(thick)) (line edadpr2 edadedad if edadedad>=15, msize(tiny) clwidth(thick)) (line edadpr3 edadedad if edadedad>=15,msize(tiny) clwidth(thick)) (line edadpr4 edadedad if edadedad>=15,msize(tiny) clwidth(thick)) (line edadpr5 edadedad if edadedad>=15,msize(tiny) clwidth(thick))(line edadpr6 edadedad if edadedad>=15,msize(tiny) clwidth(thick) lcolor(purple) mcolor(purple)),title("Edad", size(medium)) ///
	 legend(size(small)) ytitle(Probabilidad) xtitle("edad") xlab(15(10)100) ylab(0(0.1)0.6) legend(rows(3)) scheme (economist)
	 graph export "$res/Edad/BDD`m'/Edad.png",as(png) replace
	
	}
