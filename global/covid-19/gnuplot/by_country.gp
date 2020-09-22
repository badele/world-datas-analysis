
set encoding "utf8"
set locale "fr_FR.UTF-8"

# Load custom gnuplot definition
load 'global/covid-19/gnuplot/conf_'.field.'.gp'



# Function
peopleratio(x) = (x*forhab)
delta(x) = ( vD = x - prev_value, prev_value = x, max(0,vD))
min(x,y) = (x < y) ? x : y
max(x,y) = (x > y) ? x : y
country(x) = system('grep "# country_region=" ' .datafilename. ' | cut -d= -f2 | sed -n '.x.'p')

# Datafile
set datafile separator whitespace
set datafile missing "?"
set datafile commentschars "#"
set key autotitle columnhead


# Get file informations
stats datafilename nooutput
nb_countries = STATS_blocks
offset_x = 1
offset_width = 1


# Get columns header
array COUNTRIES[nb_countries]
do for [i=1:nb_countries] {
    COUNTRIES[i] = country(i)
}

# Overide some vars
ttitle="Statistique décès Covid-19 pour ".COUNTRIES[0+1]." au ".tdate
startdate="2020-01-27"


# png
set terminal pngcairo size 2048,1536 enhanced background rgb cbackground
set output 'global/covid-19/pictures/'.prefixname.'.png'

# Style
set style data lines
set border lc rgb ctext

# Grid
set grid
set xdata time
set timefmt "%Y-%m-%d"
set xtics format "%d\n%b"
set xrange [startdate:enddate]
set xtics  startdate,86400*7
set mxtics
set mytics
set ytics
set style line 102 lc rgb cgrid lt 1 lw 1
set grid  ls 102

# Legend
set key top left textcolor rgb ctext font ",18"

set size 1, 1
set multiplot

set lmargin at screen 0.15

# Plot
set origin 0, 0.3
set size 1, 0.7

set title ttitle textcolor rgb ctext font ',20'
set ylabel "Nb Décès pour 1M habitants" textcolor rgb ctext font ',15'
set xtics format ""
set xtics scale 0,0
unset key

everydays = 7

plot datafilename using 1:(peopleratio(column(field))) every everydays title COUNTRIES[1] with linespoints ls 1

# Plot
set origin 0, 0.0
set size 1, 0.3

#set boxwidth 0.7
#set style fill solid
#set style data histograms

unset title
set ylabel "Nb Décès / jour" textcolor rgb ctext font ',15'
set xtics format "%d\n%b"
set style fill solid border -1
set tmargin 0.0

prev_value = NaN
plot datafilename using 1:(delta(column('deaths'))) every everydays title COUNTRIES[1] with boxes ls 3


# # Save also to svg format
# set terminal svg enhanced size 1024,728
# set output 'global/covid-19/pictures/'.prefixname.'_high.svg'
# set object rectangle from screen 0,0 to screen 1,1 behind fillcolor rgb cbackground fillstyle solid noborder
# replot

# # Save also to eps format
# set terminal postscript eps enhanced background rgb cbackground color font 'Helvetica,8'
# set output 'global/covid-19/pictures/'.prefixname.'_high.eps'
# replot
