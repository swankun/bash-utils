#!/bin/bash

rename "s/_LATE//" *
prefix=$(ls $PWD | grep -o '^.*[a-z]_[0-9]\{5,\}_' | uniq | grep -o '^.*[a-z]')
names=($(echo $prefix | grep -o '^.*[a-z]'))
for name in "${names[@]}"
do
    mkdir $name > /dev/null 2>&1
    mv $name* $name/ > /dev/null 2>&1
    cd $name/
    n=0;
    if [ $(ls -1 *.pdf 2>/dev/null | wc -l) != 0 ]; then	
	for file in *.pdf; do 
	    mv "${file}" report_"${n}".pdf; 
	    n=$((n+1)); 
        done
    elif [ $(ls -1 *.docx 2>/dev/null | wc -l) != 0 ]; then
       	for file in *.docx; do 
	    mv "${file}" report_"${n}".docx; 
	    n=$((n+1)); 
        done
    fi
    if [ $(ls -1 *.m 2>/dev/null | wc -l) != 0 ]; then
	rename 'y/ /_/' *.m	# replace spaces with _
	rename "s/$name_.*[0-9]_.*[0-9]_//" *.m
    fi
    cd ../
done

