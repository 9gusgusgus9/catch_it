#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -a argosfilename -s filename -e epochs"
   echo -e "\t-a argosfilename to run"
   echo -e "\t-s filename to save the results"
   echo -e "\t-e epochs of testing (suggested value 50)"
   exit 1 # Exit script after printing help
}

while getopts "a:s:e:" opt
do
   case "$opt" in
      a ) argosfilename="$OPTARG" ;;
      s ) filename="$OPTARG" ;;
      e ) epochs="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

if [ -z "$argosfilename" ] || [ -z "$filename" ] || [ -z "$epochs" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

for i in $(seq "$epochs")
do
  argos3 -c $argosfilename | grep ", !!marker!!" | sed 's/, !!marker!!//' >> $filename
  a='Simulation'
  b='ended'
  c="${a} ${i} ${b}"
  echo "${c}"
done