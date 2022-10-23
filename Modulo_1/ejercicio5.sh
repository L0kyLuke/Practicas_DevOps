#!/bin/bash
if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 != "" ]]
then
    echo "Debes introducir 2 parámetros"
elif [[ $1 != http?(s)://* ]]
then
    echo "El primer parámetro debe ser una URL"
else
    curl -s $1 > web.txt
    encontrado=$(grep -o $2 web.txt | wc -w)
    linea=$(grep -o -n -w  $2  web.txt | head -n 1 | cut -d ':' -f1)
    if [[ $encontrado -eq 0 ]]
    then
        echo "No se ha encontrado la palabra '"$2"'"
    elif [[ $encontrado -eq 1 ]]
    then
        echo "La palabra '"$2"' aparece $encontrado vez"
        echo "Aparece únicamente en la línea $linea"
    else
        echo "La palabra '"$2"' aparece $encontrado veces"
        echo "Aparece por primera vez en la línea $linea"
    fi
fi
