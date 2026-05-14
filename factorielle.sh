#!/bin/bash
[[ $1 =~ ^[0-9]+$ ]] || { echo "$1 n'est pas un entier"; exit 1; }
for((r=1,i=1;i<=$1;i++)); do r=$((r*i)); done
echo "$1! = $r"
