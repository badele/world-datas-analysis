# Constant
cbackground="#212121"
ctext="#D8D9DA"
cgrid='#464646'

# Load custom gnuplot definition
load 'global/covid-19/gnuplot/conf_filter_for_'.field.'.gp'

# Function
peopleratio(x) = (x*forhab)
country(x) = system('grep "# country_region=" ' .datafilename. ' | cut -d= -f2 | sed -n '.x.'p')

# Datafile
set datafile separator whitespace
set datafile missing "?"
set datafile commentschars "#"
set key autotitle columnhead

# Date format
set timefmt "%Y-%m-%d"

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
set xrange [0:nbdays+addday]
set xtics
set mxtics
set mytics
set ytics
set y2tics
set style line 102 lc rgb cgrid lt 1 lw 1
set grid  ls 102

# Legend
unset key
set key at -10,-10 # fix bug
set key textcolor rgb ctext font ",8"


# Draw labels
do for [i=0:nb_countries-1] {
    stats datafilename index i using field nooutput
    set arrow i+10 from STATS_index_max+offset_x, peopleratio(STATS_max) to STATS_index_max+offset_x+offset_width, peopleratio(STATS_max) ls i+1 nohead
    set label i+10 sprintf("%s (%d)",COUNTRIES[i+1],peopleratio(STATS_max)) at STATS_index_max+offset_x, peopleratio(STATS_max) offset 0,.5 font ",8" tc rgb ctext
}

# Plot
plot for [i=0:nb_countries-1] datafilename index i using (peopleratio(column(field))) with linespoints ls i+1

# Save also to svg format
set encoding utf8
set terminal svg enhanced size 1024,728
set output 'global/covid-19/pictures/'.prefixname.'_high.svg'
set object rectangle from screen 0,0 to screen 1,1 behind fillcolor rgb cbackground fillstyle solid noborder
replot

# Save also to eps format
set encoding utf8
set terminal postscript eps enhanced background rgb cbackground color font 'Helvetica,8'
set output 'global/covid-19/pictures/'.prefixname.'_high.eps'
replot
