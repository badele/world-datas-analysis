# Query
prefixname='countries_'.field.'_filter_'.nbvalue.'_for_'.forhab.'hab'
datafilename='international/covid-19/datas/'.prefixname.'.gdata'
tdate=system('grep "^202" '.datafilename.' | cut -d" " -f1 | sort | tail -n1')

# Vars
nbdays = 220
addday = 2
limitline=1700

ttitle="Nb de cas Covid19 par pays au ".tdate
ytitle='Pour 1M habitants'
xtitle="Jours (à partir du 1er cas constaté pour pour 1 million habitants)"
ltitle='Barre de '.limitline.' cas pour 1M million habitants'

# Title
set title ttitle textcolor rgb ctext font ',20'
set ylabel ytitle textcolor rgb ctext font ',15'
set xlabel xtitle textcolor rgb ctext font ',15'

# Horizontal line comparison
set arrow 1 from 0,limitline to nbdays+addday,limitline nohead dt 2 lc rgb '#AAAAAA'
set label ltitle at 0.5,limitline+4 offset 0,.5 font ",8" tc rgb '#AAAAAA'

# set arrow 2 from 43, 0 to 43, graph 1 dt 2 lc rgb '#77BE69' nohead
# set arrow 3 from 46, 0 to 46, graph 1 dt 2 lc rgb '#FADE2B' nohead
# set arrow 4 from 37, 0 to 37, graph 1 dt 2 lc rgb '#F24865' nohead
# #set arrow 5 from 34, 0 to 34, graph 1 dt 2 lc rgb '#5694F2' nohead
# set arrow 6 from 28, 0 to 28, graph 1 dt 2 lc rgb '#FF9830' nohead
# set arrow 7 from 52, 0 to 52, graph 1 dt 2 lc rgb '#B876D9' nohead
# #set arrow 8 from 43, 0 to 43, graph 1 dt 2 lc rgb '#FADE2B' nohead
# set arrow 9 from 35, 0 to 36, graph 1 dt 2 lc rgb '#77BE69' nohead

# set label 2 "France - 43 Jours" at 43,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
# set label 3 "US / Germany - 46 Jours" at 46,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
# set label 4 "Italy- 37 Jours" at 37,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
# #set label 5 "France / United Kingdom - 34 Jours" at 34,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
# set label 6 "Spain - 28 Jours" at 28,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
# set label 7 "Sweden - 52 Jours" at 52,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
# set label 9 "US - 36 Jours" at 36,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
