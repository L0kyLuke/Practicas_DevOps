#!/bin/bash
mkdir foo foo/dummy foo/empty
if [[ $# -eq 0 ]]
then
echo "Me encanta la bash!!" > $(pwd)/foo/dummy/file1.txt
else
echo $1 > $(pwd)/foo/dummy/file1.txt
fi
touch $(pwd)/foo/dummy/file2.txt
cat $(pwd)/foo/dummy/file1.txt > $(pwd)/foo/dummy/file2.txt
mv $(pwd)/foo/dummy/file2.txt $(pwd)/foo/empty/
