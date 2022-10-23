#!/bin/bash
cat $(pwd)/foo/dummy/file1.txt > $(pwd)/foo/dummy/file2.txt
mv $(pwd)/foo/dummy/file2.txt $(pwd)/foo/empty/
