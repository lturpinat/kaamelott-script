#!/bin/sh

#Retourne le chemin d'accès à l'épisode $2, du livre $1 ou bien retourne "1" s'il n'existe pas
findEpisode(){
    if ls "Livre $1" | egrep -q "$2.*\.mkv" ; then
        echo $(echo "Livre $1/"$(ls "Livre $1" | egrep "$2.*\.mkv"))
    else
        return 1
    fi
}

#Vérifie si un épisode existe, sinon retourne "1"
doesEpisodeExists(){
    if ! ls "Livre $1" | egrep -q "$2.*\.mkv" ; then return 1 ; fi
}

#Convertie la syntaxe conventionnelle des épisodes (1,2,10) pour celle utilisée dans la série Kaamelott
#ex: 1 -> 001 ; 10 --> 010 ; 101 --> 101
convertEpisode(){
    if [ "$1" -lt 10 ] ; then
        echo "00$1"
    elif [ "$1" -lt 100 ] ; then
        echo "0$1"
    else
        echo "$1"
    fi
}

printAsciiArt(){
    cat << "EOF"

dP     dP                                       dP            dP     dP
88   .d8'                                       88            88     88
88aaa8P'  .d8888b. .d8888b. 88d8b.d8b. .d8888b. 88 .d8888b. d8888P d8888P
88   `8b. 88'  `88 88'  `88 88'`88'`88 88ooood8 88 88'  `88   88     88
88     88 88.  .88 88.  .88 88  88  88 88.  ... 88 88.  .88   88     88
dP     dP `88888P8 `88888P8 dP  dP  dP `88888P' dP `88888P'   dP     dP

EOF
}

#Affichage un message de transition d'approximativement 1 seconde
transitionAnimation(){
    echo -e "\e[91m[Changement d'épisode en cours...]"
    for i in $(seq 1 40) ; do
        echo -n "#"
        sleep 0.02
    done
    echo -e "\n[Changement !]\e[0m"
}

printAsciiArt

echo "Entrez dernier livre regardé (chiffres romains) : " ; read entry
livre=$entry;
if [[ ! -d "Livre $livre" ]] ; then
    echo -e "\e[91m\e[1m /!\\ Livre inconnu de votre bibliothèque /!\\ \e[0m"
    exit 1
fi

echo "Entrez dernier épisode regardé : " ; read entry
episode=$(convertEpisode $entry);

clear

#À amméliorer avec un système de menu
while true ; do
    #Vérifie si l'épisode existe
    if doesEpisodeExists "$livre" "$episode" ; then
        echo "~ Lecture en cours ~"
        echo -e "\e[1mLivre :\e[0m $livre"
        #Convertie le nom de fichier pour le rendre plus lisible
        readableEpisodeName=$(ls "Livre $livre" | egrep "$episode.*\.mkv" | sed -r "s/^Kaamelott - s..e... - //g" | sed -e "s/\.mkv//g")
        echo -e "\e[1mEpisode :\e[0m $readableEpisodeName (n°$episode)"
        #Lancement de mpv en plein écran, 3.5s après le début de l'épisode (après générique), la sortie standard est redirigée dans le néant
        mpv --fs --start=3.5 "$(findEpisode "$livre" "$episode")" 2&> /dev/null

        #Vérification si le numéro n'épisode n'est pas déja formatté (ex: 010) --> empêche l'addition
        if echo "$episode" | egrep -q "[0-9]{3}" ; then
            #Dans ce cas, conversion de la variable en base dix (passage de 010 --> 10)
            episode=$((10#$episode)) #Lit la variable comme un entier de base 10
        fi
        #Passage à l'épisode suivant
        episode=$(convertEpisode $(($episode + 1)));

        transitionAnimation
        clear
    else
        echo -e "\e[91m\e[1m /!\\ Episode inconnu /!\\ \e[0m"
        #Comme n° épisode inconnu, génération d'en entier entre [1;100] pour lancer la lecture
        episode=$(convertEpisode $(shuf -i 1-$(find Livre\ III/ -regex ".*\.mkv$" | wc -l) -n 1 ));
        sleep 2
        transitionAnimation
        clear
    fi

done
