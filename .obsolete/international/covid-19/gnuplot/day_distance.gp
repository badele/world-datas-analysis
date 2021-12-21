# Constant
cbackground="#212121"
ctext="#D8D9DA"
cgrid='#464646'
prefixname=field.'_day_distance_for_1M'
filename='international/covid-19/datas/'.prefixname.'.gdata'
filtername='international/covid-19/datas/'.prefixname.'_filter.gindex'

# Load custom gnuplot definition
load 'international/covid-19/gnuplot/conf_'.field.'.gp'

# Function
peopleratio(x) = (x*unit)
getindexname(x) = system('sed -n '.x.'p '.filtername.' | cut -d"|" -f2' )
getblockid(x) = system('sed -n '.x.'p '.filtername.' | cut -d"|" -f1' )

# Datafile
set datafile separator whitespace
set datafile missing "?"
set datafile commentschars "#"
set key autotitle columnhead

# Date format
set timefmt "%Y-%m-%d"

# Get file informations
nb_blocks = system('cat '.filtername.' | wc -l' )
offset_x = 1
offset_width = 1

# Get columns header
array INDEXNAME[nb_blocks]
array BLOCKID[nb_blocks]
do for [i=1:nb_blocks] {
    INDEXNAME[i] = getindexname(i)
    BLOCKID[i] = getblockid(i) + 0
}

# png
set terminal pngcairo size 2048,1536 enhanced background rgb cbackground
set output 'international/covid-19/pictures/'.prefixname.'.png'

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
do for [i=1:nb_blocks] {
    stats filename index BLOCKID[i] using field nooutput
    set arrow i+10 from STATS_index_max+offset_x, peopleratio(STATS_max) to STATS_index_max+offset_x+offset_width, peopleratio(STATS_max) ls i nohead
    set label i+10 sprintf("%s (%d)",INDEXNAME[i],peopleratio(STATS_max)) at STATS_index_max+offset_x, peopleratio(STATS_max) offset 0,.5 font ",8" tc rgb ctext
}

# Plot
plot for [i=1:nb_blocks] filename index BLOCKID[i] using (peopleratio(column(field))) with linespoints ls i

# Save also to svg format
set encoding utf8
set terminal svg enhanced size 1024,728
set output 'international/covid-19/pictures/'.prefixname.'_high.svg'
set object rectangle from screen 0,0 to screen 1,1 behind fillcolor rgb cbackground fillstyle solid noborder
replot

# Save also to eps format
set encoding utf8
set terminal postscript eps enhanced background rgb cbackground color font 'Helvetica,8'
set output 'international/covid-19/pictures/'.prefixname.'_high.eps'
replot
