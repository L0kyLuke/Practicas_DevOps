#!/bin/bash
readonly web="https://www.falve.co.nz/" 2>/dev/null
curl -s $web > web.txt
encontrado=$(grep -o $1 web.txt | wc -w)
linea=$(grep -o -n -w  $1  web.txt | head -n 1 | cut -d ':' -f1)
if [[ $encontrado -eq 0 ]]
then
    echo "No se ha encontrado la palabra '"$1"'"
elif [[ $encontrado -eq 1 ]]
then
    echo "La palabra '"$1"' aparece $encontrado vez"
    echo "Aparece únicamente en la línea $linea"
else
    echo "La palabra '"$1"' aparece $encontrado veces"
    echo "Aparece por primera vez en la línea $linea"
fi