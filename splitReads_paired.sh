#!/bin/bash


#if this script has every error, exit
set -e

############################################
R1gz=$1 
R2gz=$2 
outputR1_train_fastq=$3 
outputR1_test_fastq=$4 
outputR2_train_fastq=$5 
outputR2_test_fastq=$6
test_percentage=${7:-10}
###########################################


#check whether the name in R1 and R2 is the same and in the same order, and output some stat data
function check_R1R2_seqName()
{
    R1File=$1
    R2File=$2
    percentage=$3

    awk '{if (NR % 4 == 1) {print $1}}' $R1File > $R1File.checkName
    awk '{if (NR % 4 == 1) {print $1}}' $R2File > $R2File.checkName
    diff -q $R2File.checkName $R2File.checkName 1>/dev/null
    if [ $? == 0 ]
    then
        echo "Finished name checking"
    else
        echo "[ERROR] Names in R1/R2 are not the same"
        exit 1
    fi

    n1=$(wc -l < $R1File.checkName)
    n2=$(wc -l < $R2File.checkName)
    echo "You have "$n1" forward reads"
    echo "You have "$n2" reverse reads"

    rm $R1File.checkName $R2File.checkName

    # get the number of reads that correspond to the test_percentage 
    nTest=$[$n1 * $percentage / 100]
    nTrain=$[$n1 - $nTest]
    echo "Making test file from "$nTest" reads"
    echo "Making training file from "$nTrain" reads"
}




function split()
{
    FQ1=$1
    FQ2=$2
    # The names of the test/train subsets you wish to create
    FQ1train=$3
    FQ1test=$4
    FQ2train=$5
    FQ2test=$6
    nTrain=$7
    nTest=$8

    # paste the two FASTQ such that the 
    # header, seqs, seps, and quals occur "next" to one another
    paste $FQ1 $FQ2 | \
    # "linearize" the two mates into a single record.  Add a random number to the front of each line
          awk 'BEGIN{srand()}; {OFS="\t"; \
               getline seqs; getline sep; getline quals; \
               print rand(),$0,seqs,sep,quals}' | \
    # sort by the random number
          sort -k1,1 > pasted.txt

    # split the merged reads
    head -n $nTest pasted.txt > testData.pasted.txt
    tail -n $nTrain pasted.txt > trainData.pasted.txt

    # unmerge the reads
    awk -v FQ1test="$FQ1test" \
        -v FQ2test="$FQ2test" \
        '{OFS="\n"; \
        print $2" "$3,$6,$8,$10 >> FQ1test; \
        print $4" "$5,$7,$9,$11 >> FQ2test}' \
        testData.pasted.txt

    awk -v FQ1train="$FQ1train" \
        -v FQ2train="$FQ2train" \
        '{OFS="\n"; \
        print $2" "$3,$6,$8,$10 >> FQ1train; \
        print $4" "$5,$7,$9,$11 >> FQ2train}' \
        trainData.pasted.txt

    #clean
    rm testData.pasted.txt trainData.pasted.txt pasted.txt
}

#help info
if [ $# -lt 1 ] 
then
  echo "Usage: ./splitReads_paried.sh R1 R2 outputR1train outputR1test outputR2train outputR2test integer (1-99, default 10)"
  exit 1
elif [ $1 == --help -o $1 == -h ] 
then
  echo "Usage: ./splitReads_paried.sh R1 R2 outputR1train outputR1test outputR2train outputR2test integer (1-99, default 10)"
  exit 1
fi


#check argument
if [[ $R1gz != *.fastq.gz && $R1gz != *.fq.gz ]]
then 
    echo "[ERROR] The file "$R1gz" is neither in fastq.gz or fq.gz format"
    exit 1
fi

if [[ $R2gz != *.fastq.gz && $R2gz != *.fq.gz ]]
then 
    echo "[ERROR] The file "$R2gz" is neither in fastq.gz or fq.gz format"
    exit 1
fi

if ! [[ $test_percentage =~ ^[0-9]+$ ]]
then
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_paried.sh R1 R2 outputR1train outputR1test outputR2train outputR2test integer (1-99, default 10)"
    exit 1
elif [ $test_percentage -ge 100 -o $test_percentage -le 0 ]
then 
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_paried.sh R1 R2 outputR1train outputR1test outputR2train outputR2test integer (1-99, default 10)"
    exit 1
fi


##begin

#unzip fq for convenience
outputR1=outputR2
outputR2=outputR1
zcat $R1gz > $outputR1
zcat $R2gz > $outputR2

check_R1R2_seqName $outputR1 $outputR2 $test_percentage
split $outputR1 $outputR2 $outputR1_train_fastq $outputR1_test_fastq $outputR2_train_fastq $outputR2_test_fastq $nTrain $nTest

gzip $outputR1_train_fastq
gzip $outputR1_test_fastq
gzip $outputR2_train_fastq
gzip $outputR2_test_fastq

rm $outputR1 $outputR2
