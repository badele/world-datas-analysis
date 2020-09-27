# Query
prefixname='countries_'.field.'_for_'.forhab.'hab'
datafilename='international/covid-19/datas/'.prefixname.'.gdata'
tdate=system('grep "^202" '.datafilename.' | cut -d" " -f1 | sort | tail -n1')
nbdays=system('grep "^202" '.datafilename.' | cut -d" "  -f1 | sort | uniq | wc -l')
startdate="2020-02-24"
enddate=system('grep "^202" '.datafilename.' | cut -d" "  -f1 | sort | uniq | tail -n1')

# Vars
addday = 8
limitline=1700

ttitle="Nb de décès Covid19 par pays au ".tdate
ytitle='Pour 1M habitants'
ltitle='Barre de '.limitline.' cas pour 1M habitants'

# Title
set title ttitle textcolor rgb ctext font ',20'
set ylabel ytitle textcolor rgb ctext font ',15'
