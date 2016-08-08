#!/bin/bash

args=($@)

firstRzn=${args[0]}
numRzn=${args[1]}
result=${args[2]}
calc=${args[3]}

for ((i=4; i < ${#args[@]} ; i++))
do

	name[$(($i-4))]=`echo ${args[$i]} | awk -F'=' '{print $1}'`
	file[$(($i-4))]=`echo ${args[$i]} | awk -F'=' '{print $2}'`
done

for ((rzn=0; rzn < $numRzn ; rzn++))
do
	command="gdal_calc.py "
	printf -v rznIDZero "%03d" $((rzn+firstRzn))

	for ((i=0;i<${#name[@]};i++))
	do
		gdal_translate -of GTiff ${file[$i]}_rzn$rznIDZero.asc ${name[$i]}.tif
		command="$command -${name[$i]} ${name[$i]}.tif"
	done

	command="$command --outfile=result.tif --NoDataValue=-1.00000 --calc=$calc --overwrite"
	$command

	gdal_translate -of AAIGrid result.tif ${result}_rzn$rznIDZero.asc
	rm ${result}_rzn$rznIDZero.asc.aux.xml
done

rm result.tif

for ((i=0; i < ${#name[@]} ; i++))
do
	rm ${name[$i]}.tif
done 

./SARasterStat ${result} $firstRzn $numRzn ${result}
