project="achilles"


if test -z $1
then
        echo "Usage: drop_db.sh [development|testing|production]";
else
	db="$project""_""$1"
        sudo mysql -e "drop database $db; create database $db"

fi

