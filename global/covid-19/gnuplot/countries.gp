
set encoding "utf8"
set locale "fr_FR.UTF-8"

# Load custom gnuplot definition
load 'global/covid-19/gnuplot/conf_'.field.'.gp'

# Function
peopleratio(x) = (x*forhab)
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
set xtics format "%d %B"
set xrange [startdate:enddate]
set xtics  startdate,86400*7
set mxtics
set mytics
set ytics
set y2tics
set style line 102 lc rgb cgrid lt 1 lw 1
set grid  ls 102

# Legend
set key top left textcolor rgb ctext font ",18"

# Plot
plot for [i=0:nb_countries-1] datafilename index i using 1:(peopleratio(column(field))) title COUNTRIES[i+1] with linespoints ls i+1

# Save also to svg format
set terminal svg enhanced size 1024,728
set output 'global/covid-19/pictures/'.prefixname.'_high.svg'
set object rectangle from screen 0,0 to screen 1,1 behind fillcolor rgb cbackground fillstyle solid noborder
replot

# Save also to eps format
set terminal postscript eps enhanced background rgb cbackground color font 'Helvetica,8'
set output 'global/covid-19/pictures/'.prefixname.'_high.eps'
replot
