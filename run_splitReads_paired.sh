#!/bin/bash

#if this script has every error, exit
set -e

#############################################################
#dir contains R1 and R2, in fastq.gz format (the end of file must be ".fastq.gz" or ".fq.gz")
inputDir=$1
outputDir=$2
test_percentage=${3:-10} #percentage of data to reserve as test data (must be integer!!!)
#############################################################

SOURCE=$(dirname $0})

#help info
if [ $# -lt 1 ] 
then
  echo "Usage: ./splitReads_paried.sh inputDir outputDir  integer (1-99, default 10)"
  exit 1
elif [ $1 == --help -o $1 == -h ] 
then
  echo "Usage: ./splitReads_paried.sh inputDir outputDir  integer (1-99, default 10)"
  exit 1
fi


#check argument
if [ ! -d $inputDir ]
then 
    echo "[ERROR]" $inputDir " is not a directory"
    echo "Usage: ./splitReads_paried.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
fi

if [ ! -d $outputDir ]
then 
    echo "[ERROR]" $outputDir " is not a directory"
    echo "Usage: ./splitReads_paried.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
fi

if ! [[ $test_percentage =~ ^[0-9]+$ ]]
then
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_paried.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
elif [ $test_percentage -ge 100 -o $test_percentage -le 0 ]
then 
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_paried.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
fi



##begin


for R1gz in $inputDir/*R1*
do
    echo 'Processing' $R1gz
    if [[ $R1gz == *.fastq.gz ]]
    then
        extension=".fastq.gz"
    elif [[ $R1gz == *.fq.gz ]]
    then
        extension=".fq.gz"
    else
        echo "[ERROR] The file is neither in fastq.gz or fq.gz format"
        exit 1
    fi       
    R2gz=${R1gz/"R1"/"R2"}
    outputR1=$outputDir/$(basename $R1gz $extension)
    outputR2=$outputDir/$(basename $R2gz $extension)

    bash $SOURCE/splitReads_paired.sh $R1gz $R2gz $outputR1.train.fastq $outputR1.test.fastq $outputR2.train.fastq $outputR2.test.fastq $test_percentage


done
