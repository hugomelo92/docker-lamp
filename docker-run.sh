#!bin/sh

#carregando configuracoes
value=`cat configs/.config | grep apache:port=`
APACHE_PORT=$(echo "$value" | sed -e s/apache:port=/""/g)
echo "Porta Apache: $APACHE_PORT"
value=`cat configs/.config | grep mysql:port=`
MYSQL_PORT=$(echo "$value" | sed -e s/mysql:port=/""/g)
echo "Porta MySql: $MYSQL_PORT"
value=`cat configs/.config | grep ssh:port=`
SSH_PORT=$(echo "$value" | sed -e s/ssh:port=/""/g)
echo "Porta ssh: $SSH_PORT"

#capturando versao do php
if [ "$1" = "" ]
then
    TAG=latest
else
    TAG=$1
fi

#removendo containers
docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm

#criando volume de persistencia
docker volume create --name persistence

#atualizando a imagem
docker pull hugobmelo/lamp:$TAG

#iniciando a imagem
docker run -d --name lamp -v persistence:/var/lib/mysql -v ${PWD}/www:/var/www -v ${HOME}/.ssh:/root/.ssh -v ${PWD}/configs/.gitconfig:/root/.gitconfig -v ${PWD}/sites-available:/etc/apache2/sites-available -p $APACHE_PORT:80 -p $MYSQL_PORT:3306 -p $SSH_PORT:22 hugobmelo/lamp:$TAG tail -f /dev/null

sleep 2

#executando servicos
docker exec lamp /bin/bash init.sh

#entrando na imagem
docker exec -it lamp bash

#parando a imagem (exit)
docker stop lamp