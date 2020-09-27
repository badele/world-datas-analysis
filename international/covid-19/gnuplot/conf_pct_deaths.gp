# Vars
nbdays = 55
addday = 2
limitline=150

ttitle="Nb de décès Covid19 par pays au ".tdate
ytitle="Pour 1 million habitants"
xtitle="Jours (à partir du 1er décès constaté) pour 1 million habitants"
ltitle='Barre de '.limitline.' décès pour 1 million habitants"

# Title
set title ttitle textcolor rgb ctext font ',20'
set ylabel ytitle textcolor rgb ctext font ',15'
set xlabel xtitle textcolor rgb ctext font ',15'

# Horizontal line comparison
set arrow 1 from 0,limitline to nbdays+addday,limitline nohead dt 2 lc rgb '#AAAAAA'
set label ltitle at 0.5,limitline+4 offset 0,.5 font ",8" tc rgb '#AAAAAA'

set arrow 2 from 25, 0 to 25, graph 1 dt 2 lc rgb '#77BE69' nohead
#set arrow 3 from 27, 0 to 27, graph 1 dt 2 lc rgb '#FADE2B' nohead
set arrow 4 from 24, 0 to 24, graph 1 dt 2 lc rgb '#F24865' nohead
#set arrow 5 from 34, 0 to 34, graph 1 dt 2 lc rgb '#5694F2' nohead
set arrow 6 from 18, 0 to 18, graph 1 dt 2 lc rgb '#FF9830' nohead
set arrow 7 from 30, 0 to 30, graph 1 dt 2 lc rgb '#B876D9' nohead
#set arrow 8 from 43, 0 to 43, graph 1 dt 2 lc rgb '#FADE2B' nohead
set arrow 9 from 32, 0 to 32, graph 1 dt 2 lc rgb '#77BE69' nohead

set label 2 "United Kingdom / France - 25 Jours" at 25,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
#set label 3 "US - 27 Jours" at 27,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 4 "Italy- 24 Jours" at 24,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
#set label 5 "France / United Kingdom - 34 Jours" at 34,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 6 "Spain - 18 Jours" at 18,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 7 "Sweden - 30 Jours" at 30,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 9 "US - 32 Jours" at 32,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
