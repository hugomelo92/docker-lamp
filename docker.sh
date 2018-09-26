#!/bin/sh

ssh () {
	# entrando na imagem
	docker exec -it lamp bash
}

stop () {
	# parando a imagem (exit)
	docker stop lamp
}

pull () {
	# atualizando a imagem
	docker pull hugobmelo/lamp -a
}

run () {

	# verificando se tem lamp rodando
	running=`docker ps --filter name=lamp | grep lamp`
	if [ "$running" != "" ]
	then
		echo "lamp is already running!"
		return
	fi

	# verificando se existe lamp
	exists=`docker ps -a | grep lamp`
	if [ "$exists" != "" ]
	then
		docker rm lamp
	fi

	# carregando configuracoes
	value=`cat configs/.config | grep http:port=`
	HTTP_PORT=$(echo "$value" | sed -e s/http:port=/""/g)
	echo "Porta http: $HTTP_PORT"
	value=`cat configs/.config | grep https:port=`
	HTTPS_PORT=$(echo "$value" | sed -e s/https:port=/""/g)
	echo "Porta https: $HTTPS_PORT"
	value=`cat configs/.config | grep mysql:port=`
	MYSQL_PORT=$(echo "$value" | sed -e s/mysql:port=/""/g)
	echo "Porta MySql: $MYSQL_PORT"
	value=`cat configs/.config | grep ssh:port=`
	SSH_PORT=$(echo "$value" | sed -e s/ssh:port=/""/g)
	echo "Porta ssh: $SSH_PORT"
	value=`cat configs/.config | grep php:version=`
	PHP_VERSION=$(echo "$value" | sed -e s/php:version=/""/g)
	echo "Versao PHP: $PHP_VERSION"

	# criando volume de persistencia
	docker volume create --name persistence

	# iniciando a imagem
	docker run -d --name lamp -v persistence:/var/lib/mysql -v ${PWD}/www:/var/www -v ${HOME}/.ssh:/root/.ssh -v ${PWD}/configs/.gitconfig:/root/.gitconfig -v ${PWD}/configs/mysqld.cnf:/etc/mysql/mysql.conf.d/mysqld.cnf -v ${PWD}/sites-available:/etc/apache2/sites-available -p $HTTP_PORT:80 -p $HTTPS_PORT:443 -p $MYSQL_PORT:3306 -p $SSH_PORT:22 hugobmelo/lamp:$PHP_VERSION tail -f /dev/null

	sleep 2

	# executando servicos
	docker exec lamp /bin/bash init.sh
}

default () {
	running=`docker ps --filter name=lamp | grep lamp`

	if [ "$running" != "" ]
	then
		# entrando na imagem
		docker exec -it lamp bash

		# parando a imagem (exit)
		docker stop lamp

		return
	fi

	pull

	run

	ssh

	stop
}

case "$1" in
	"run") run ;;
	"ssh") ssh ;;
	"stop") stop ;;
	"pull") pull ;;
	*) default ;;
esac
