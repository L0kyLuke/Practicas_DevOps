#!/bin/bash
mkdir foo foo/dummy foo/empty
echo "Me encanta la bash!!" > $(pwd)/foo/dummy/file1.txt
touch $(pwd)/foo/dummy/file2.txt
