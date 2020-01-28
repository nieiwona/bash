#!/bin/bash

# Skrypt potrzebowal chmod +x żeby być wykonywalny
# Skrypt jest obsługiwany przez komendy:
# $ cat trees.txt | ./trol.sh -l
# $ cat trees.txt | ./trol.sh -w
# $ ./trol.sh -d trees.txt -s
# $ ./trol.sh -d http://bioputer.mimuw.edu.pl/gorecki/urec/expdata/gtrees.txt -l


function Usage()
{
cat<<EOF
Usage: $0 [-h] [-d optional] file [-w] [-l] [-s] 
-h 
-d adres pliku, lokalny lub HTTP, jesli opcja nie jest podana plik jest wczytywany ze standardowego wejscia
-w podaj liste etykiet wezlow wewnetrznych w calym pliku (bez powtorzen)
-l podaj liste etykiet lisci w clym pliku (bez powtorzen)
-s podaj statystyki: liczba lisci, liczba wezlow wewnetrznych, calkowita liczba wezlow dla kazdego drzewa osobno
EOF

} 

# Jesli nie podano argumentow wypisz Usage
if [ "$*" = "" ]  # mozna tez tak: if [ -z "$*" ]
then
    Usage 
    # Zwroc kod bledu
    exit 20
fi

# Obsluga getopt
set -- `getopt hd:lws $*` # możliwe opcje, w tym opcja -d ma dodatkowy parametr  


# Ustawienie odpowiednich flag dla opcji
while [ "$1" != -- ]
do
    case $1 in
        -h)   HFLG=1;;
        -d)   DFLG=$2; shift;; # kiedy podane dwa argumenty przejdz do kolejnego
	-l)   LFLG=1;; 
	-w)   WFLG=1;;
	-s)   SFLG=1;;
    esac
    shift   # nastepna opcja
done

shift   # pomin  --

# Jesli podano argument -h wypisz Usage
if [ "$HFLG" = 1 ] 
then
    Usage 
    exit 0
fi

input="" # zmienna globalna


# Gdy nie podano argumentu -d wczytaj ze standardowego wejscia
# Gdy podano -d wczytaj wskazany plik 
# lub wczytaj plik spod adresu HTTP
if [ "$DFLG" ] 
then 
    if [ -f "$DFLG" ]; then
    input=$(cat $DFLG) # jesli input jest plikem zrob cat i zapisz pod zmienna input
    elif [[ $DFLG == http* ]]; then
    wget $DFLG  # sciagnij plik spod podanego jako argument adresu http
    input=$(echo $DFLG | grep -o -E '[^/]*$') # wyciagnij z adresu http nazwe pliku, ktora jest za ostatnim /
    input=$(cat $input) # zrob cat na pliku
    fi
elif [ $DFLG=="" ] # jesli nie podano argumentu -d 
then
    input=$(cat) # wczytaj ze standardowego wejscia
fi


# Podaj liste etykiet wezlow wewnetrznych w calym pliku (bez powtorzen)
if [ "$WFLG" ] 
then 
    # za pomoca grep wybierz tylko litery za nawiasem zamykajacym
    # nastepnie za pomoca sed usun wyciagniety nawias zamykajacy i przecinek
    # za pomoca sort -u wybierz unikatowe litery
    echo $input | grep -o -E "\),?([a-z]*)" | sed "s/)//" | sed "s/,//" | sort -u

fi


# Podaj liste etykiet lisci w calym pliku (bez powtorzen)
if [ "$LFLG" ] 
then 
    # za pomoca grep wybierz tylko litery przed nawiasem otwierajacym lub przecinkiem
    # za pomoca sed usun wyciagniety nawias otwierajacy
    # usun pusta linie
    # za pomoca sort -u wybierz unikatowe litery
    echo $input | grep -o -E "\(([a-z]*)|,([a-z]*)" | sed "s/(//" | sed "s/,//" | sed -r '/^\s*$/d' | sort -u
fi


# Podaj statystyki: liczba lisci, liczba wezlow wewnetrznych, calkowita liczba wezlow dla kazdego wezla osobno

if [ "$SFLG" ] 
then 
    while read -r line
    do 
        # funkcje listujace lisce i wezly sa wzorowane na poprzednich
        # wc -l zlicza slowa w linii 
        a=$(echo $line | grep -o -E "\(([a-z]*)|,([a-z]*)" | sed "s/(//" | sed "s/,//" | sed -r '/^\s*$/d' | wc -l)
        b=$(echo $line | grep -o -E "\),?([a-z]*)" | sed "s/)//" | sed "s/,//" | wc -l)
        c=$(($a + $b))
        echo $a $b $c
    done <<< $input
fi

exit 0