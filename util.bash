#!/bin/bash
function users
{
    cat /etc/passwd | awk 'BEGIN {FS=":"}{print $1,$6}' | sort
}

function processes
{
    ps -ela | awk '{print $4,$14}'
}

function help
{
    echo -u,--users - Перечень пользователей и домашних директорий
    echo -p,--processes - Текущие процессы
    echo -h,--help - Выводит это окно
    echo -l PATH, --log PATH - Перенаправление потока вывода в файл по пути PATH
    echo -e PATH, --errors PATH - Перенаправление потока ошибок в файл по пути PATH
    exit
}

function isValidPath
{
    if [ -w ${path} ]
    then
	if [ -f ${path} ]
	then
	    #writing to this file
	    return 0
	elif [ -d ${path} ]
	then
	    #writing using this as dir
	    return 1
	else
	    #wrong path
	    return 2
	fi
    elif [[ ! -e ${path} && -w $(dirname ${path}) && -d $(dirname ${path}) ]]
    then
	return 0
    else
	#wrong path or no rights
	return 3
    fi
}

function log
{
    path=$logPath
    isValidPath
    case $? in
	0)
	    exec 1>${path}
	    ;;
	1)
	    echo log: Got dir, writing to $path/log.txt
	    exec 1>${path}/log.txt
	    ;;
	2)
	    echo log: Wrong path >&2
	    ;;
	3)
	    echo log: Wrong path or no rights to write >&2
	    ;;
	*)
	    echo log:internal error >&2
	    ;;
    esac
}

function errors
{
    path=$errorPath
    isValidPath
    case $? in
	0)
	    exec 2>${path}
	    ;;
	1)
	    echo errors: Got dir, writing errors to $path/errors.txt
	    exec 2>${path}/errors.txt
	    ;;
	2)
	    echo errors: Wrong path >&2
	    ;;
	3)
	    echo errors: Wrong path or no rights to write >&2
	    ;;
	*)
	    echo errors:intertal error>&2
	    ;;
    esac
}

SHORT=u,p,l:,h,e:
LONG=users,processes,log:,help,errors:
OPTS=$(getopt -a -n myArguments --options $SHORT --longoptions $LONG -- "$@")
#echo $OPTS

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

eval set -- "$OPTS"

while :
do
    case "$1" in
	-l | --log )
	    logPath="$2"
	    log
	    shift 2
	    ;;
	-e | --errors )
	    errorPath="$2"
	    errors
	    shift 2
	    ;;
	-h | --help)
	    help
	    ;;
	-u | --users)
	    users
	    shift;
	    ;;
	-p | --processes)
	    processes
	    shift;
	    ;;
	--)

	    shift;
	    break
	    ;;
	*)
	    echo "Unexpected option: $1"
	    help
	    ;;
    esac
done
