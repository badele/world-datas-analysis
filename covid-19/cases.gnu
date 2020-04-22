# Constant
cbackground="#212121"
ctext="#D8D9DA"
cgrid='#464646'
filename="/tmp/covid_countries_".field.".csv"
yrange=500

# Function
peopleratio(x) = x*100000

# Datafile
set datafile separator ","
set datafile missing "?"

# Get file informations
stats filename skip 1 nooutput
nbcolumns = STATS_columns
nbdays = 55
offset = 20

# Get columns header
array COLUMNS[nbcolumns]
do for [i=1:nbcolumns] {
    COLUMNS[i] = system("head -n1 ".filename. " | cut -d, -f".i)
}

# png
set terminal pngcairo size 1024,728 enhanced background rgb cbackground
set output field.".png"

# Style
set style data lines
set border lc rgb ctext

# Grid
set grid
set xrange [0:nbdays+offset]
set xtics
set mxtics
set mytics
set ytics
set y2tics
set style line 102 lc rgb cgrid lt 1 lw 1
set grid  ls 102
set yrange [0:yrange]
set y2range [0:yrange]

# Legend
unset key
set key at -10,-10 # fix bug
set key textcolor rgb ctext font ",8"

# Title
set title "Cas covid-19 confirmés par pays au ".strftime("%d/%/%Y", time(0)) textcolor rgb ctext font ',20'
set xlabel "Jours (à partir du 1er cas)" textcolor rgb ctext font ',15'
set ylabel "Nb de cas pour 100000 habitants" textcolor rgb ctext font ',15'

# Horizontal line comparison
compareline=120
set arrow 1 from 0,compareline to nbdays+offset,compareline nohead dt 2 lc rgb '#AAAAAA'
set label "Cap de ".compareline." cas pour 100000 habitants" at 0.5,compareline+4 offset 0,.5 font ",8" tc rgb '#AAAAAA'

set arrow 2 from 23, 0 to 23, graph 1 dt 2 lc rgb '#77BE69' nohead
set arrow 3 from 27, 0 to 27, graph 1 dt 2 lc rgb '#FADE2B' nohead
set arrow 4 from 30, 0 to 30, graph 1 dt 2 lc rgb '#F24865' nohead
set arrow 5 from 34, 0 to 34, graph 1 dt 2 lc rgb '#5694F2' nohead
set arrow 6 from 34, 0 to 34, graph 1 dt 2 lc rgb '#FF9830' nohead
set arrow 7 from 32, 0 to 32, graph 1 dt 2 lc rgb '#B876D9' nohead
set arrow 8 from 43, 0 to 43, graph 1 dt 2 lc rgb '#FADE2B' nohead

set label 2 "Spain - 23 Jours" at 23,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 3 "US - 27 Jours" at 27,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 4 "Italy- 30 Jours" at 30,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 5 "France / United Kingdom - 34 Jours" at 34,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 6 "Germany - 32 Jours" at 32,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'
set label 7 "Sweden - 43 Jours" at 43,graph 1 offset -1,-0.5 rotate by 90 right font ",8" tc rgb '#AAAAAA'

do for [i=2:nbcolumns] {
    stats filename using i nooutput
    set arrow i+10 from STATS_index_max+2, peopleratio(STATS_max) to STATS_index_max+3, peopleratio(STATS_max) ls i-1 nohead
    set label i+10 sprintf("%s (%d)",COLUMNS[i],peopleratio(STATS_max)) at STATS_index_max+2, peopleratio(STATS_max) offset 0,.5 font ",8" tc rgb ctext
}

plot for [i=2:nbcolumns] filename using 1:(column(i)*100000) with linespoints ls i-1 pt 7

# svg
set encoding utf8
set terminal svg enhanced size 1024,728
set output field."_high.svg"
set object rectangle from screen 0,0 to screen 1,1 behind fillcolor rgb cbackground fillstyle solid noborder
replot

# eps
set encoding utf8
set terminal postscript eps enhanced background rgb cbackground color font 'Helvetica,8'
set output field."_high.eps"
replot
