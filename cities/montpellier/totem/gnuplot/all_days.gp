
set encoding "utf8"
set locale "fr_FR.UTF-8"

# Load custom gnuplot definition
load 'cities/montpellier/totem/gnuplot/conf_all_days.gp'

# Function
delta(x) = ( vD = x - prev_value, prev_value = x, max(0,vD))
max(x,y) = (x > y) ? x : y


# Datafile
set datafile separator whitespace
set datafile missing "?"
set datafile commentschars "#"
#set key autotitle columnhead



# png
set terminal pngcairo size 2048,1536 enhanced background rgb cbackground
set output 'cities/montpellier/totem/pictures/'.prefixname.'.png'

# Style
set style data lines
set border lc rgb ctext

# Grid
set grid
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set xtics format "%d\n%b"
set xrange [startdate:enddate]
set xtics  startdate,xticstep
set mxtics
set mytics
set ytics
set style line 102 lc rgb cgrid lt 1 lw 1
set grid  ls 102

# Title
set title ttitle textcolor rgb ctext font ',20'
set ylabel ytitle1 textcolor rgb ctext font ',15'
set xlabel xtitle textcolor rgb ctext font ',15'


# Some informations
set arrow 1 from "2020-07-06" ,graph 0 to "2020-07-06",graph 1 dt 3 lw 2 lc rgb '#F24865' nohead front
set label 1 "100.000eme le 6 Juillet / 100.000 en 17 semaines" at "2020-07-06",graph 1 offset -1 , -1 right font ",10" tc rgb '#AAAAAA'

set arrow 2 from "2020-09-18" ,graph 0 to "2020-09-18",graph 1 dt 3 lw 2 lc rgb '#F24865' nohead front
set label 2 "200.000eme le 18 Septembre / 100.000 en 11 semaines" at "2020-09-18",graph 1 offset -1 , -1 right font ",10" tc rgb '#AAAAAA'

set style rect fc rgb "#F4FFFFFF" fs solid 1 noborder
set obj rect from debutconfine, graph 0 to finconfine, graph 1 front
set label 3 textconfine at debutconfine,graph 1 offset 8 , -1 left font ",10" tc rgb '#AAAAAA'

set style rect fc rgb "#F4FFFFFF" fs solid 1 noborder
set obj rect from debutvacete, graph 0 to finvacete, graph 1 front
set label 4 textvacete at debutvacete,graph 1 offset 8 , -1 left font ",10" tc rgb '#AAAAAA'


# Legend
unset key

set size 1, 1
set multiplot

set lmargin at screen 0.15

# Plot
set origin 0, 0.3
set size 1, 0.7

# Plot
plot datafilename using 1:16  with impulses ls 1

set origin 0, 0.0
set size 1, 0.3

#set boxwidth 0.7
#set style fill solid
#set style data histograms

unset title
set xtics format "%d\n%b"
set style fill solid border -1
set ylabel ytitle2 textcolor rgb ctext font ',15'
set yrange [0:]

prev_value = 0
plot datafilename using 1:(delta(column(16))) every everyjump with boxes ls 2

# Save also to svg format
# set terminal svg enhanced size 1024,728
# set output 'cities/montpellier/totem/pictures/'.prefixname.'_high.svg'
# set object rectangle from screen 0,0 to screen 1,1 behind fillcolor rgb cbackground fillstyle solid noborder
# replot

# # Save also to eps format
# set terminal postscript eps enhanced background rgb cbackground color font 'Helvetica,8'
# set output 'cities/montpellier/totem/pictures/'.prefixname.'_high.eps'
# replot
