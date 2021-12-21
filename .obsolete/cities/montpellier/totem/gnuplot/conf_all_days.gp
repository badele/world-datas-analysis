# Vars
prefixname = "albert_1er"
datafilename='cities/montpellier/totem/datas/'.prefixname.'.gdata'

startdate="2020-03-12"
enddate=system('egrep "^202" '.datafilename.' | cut -d" "  -f1 | sort | uniq | tail -n1')


debutconfine="2020-03-17"
finconfine="2020-05-11"
textconfine="Confinement du 17 Mars au 11 Mai"

debutvacete="2020-07-06"
finvacete="2020-09-01"
textvacete="Vacance été"

unitdatarow=3600
everyjump=dayrange*24
xticstep=everyjump*unitdatarow


ttitle="Comptage passages Totem Albert 1er"
ytitle1="Passages cumulés"
ytitle2="Passages quotidiens"
xtitle="Jours"
