#!/bin/bash
#
# Use the Blocking method (Flyvbjerg and Petersen, J. Chem. Phys. 91,
# 461 (1989)) to get an estimate for the standard deviation of a set
# of correlated data points (e.g., a time series from an MD
# simulation) given as a single-column data file. Script outputs the
# following:
#
# - mean of the data
# - estimate for the standard deviation of the time average
# - blocking step vs. estimated standard deviation and the standard
#   deviation thereof into file c.dat
#
# Eero Holmstrom, 2013
#

# usage
if [[ -z "$1" ]];
then
    echo "Usage: $(basename $0) [single-column data file]"
    exit 1;
fi

# assign input variables
infile=$1

#
# start loop over blocking method
#

rm -f c.dat block.dat

cp $infile block.dat
datafile="block.dat"

# get some initial values
n=$(wc $datafile | awk '{print $1}')
norig=$n
meanorig=$(awk 'BEGIN{xcum=0.0; n=0}{xcum=xcum+$1; n++}END{print xcum/n}' $datafile)
maxstd=-999.9
step=0

# do the blocking until the amount of data is down to two points or less
while [[ $(echo "$n > 2" | bc -l) -eq 1 ]]
do

#
# compute c_0 / (n-1) and sqrt() thereof, i.e., the variance and
# standard deviation for this step
#

# get mean
mean=$(awk 'BEGIN{xcum=0.0; n=0}{xcum=xcum+$1; n++}END{print xcum/n}' $datafile)

# get c_0 to compute the variance and std
czero=$(awk -v n=$n -v mean=$mean 'BEGIN{sum=0.0;}{sum=sum+($1-mean)^2;}END{print sum/n}' $datafile)
thisvar=$(awk -v n=$n -v czero=$czero 'BEGIN{print czero/(n-1)}')
thisstd=$(awk -v thisvar=$thisvar 'BEGIN{print sqrt(thisvar);}')

# get std of current std
stdofthisstd=$(awk -v thisstd=$thisstd -v n=$n 'BEGIN{ print thisstd*1/sqrt(2*(n-1)); }')

# check for maximum value of std
maxstd=$(awk -v maxstd=$maxstd -v thisstd=$thisstd 'BEGIN{ if(thisstd > maxstd) {maxstd=thisstd}; print maxstd }')

echo $step $thisstd $stdofthisstd >> c.dat

# do the blocking transform
awk 'BEGIN{i=0};

{i++;}

(i==1){prev=$1;};

(i==2){

cur=$1;
thismean=0.5*(cur+prev);
print thismean;
i=0;

};

' $datafile > datafile.temp

# replace old data with blocked data
mv datafile.temp $datafile

# get length of current data
n=$(wc $datafile | awk '{print $1}')

# increment step counter
step=$(($step+1))

done
#
# end loop over blocking method
#

# print result
echo $meanorig $maxstd

# clean up
rm -f $datafile

exit 0;

