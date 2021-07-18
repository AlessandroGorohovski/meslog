#!/bin/bash -

set -o nounset  # Treat unset variables as an error

: << COMMENT
Determining the length of some text fields of tables
and creating database tables
COMMENT

logFile=mailog.out

DBname=meslogDB
user=alessandro

echo "Check all non-ASCII characters:"
grep --color='auto' -P -n "[\x80-\xFF]" $logFile | wc -l
grep --color='auto' -P -n "[^\x00-\x7F]" $logFile | wc -l

echo "Search max length of id=xxx... tag"
# `id` VARCHAR(128) NOT NULL COMMENT 'значение поля id=xxxx из строки лога, by default 73'
perl -nE '$m=length$1if/id=(\S+)/&&$m<length$1;END{say$m}' $logFile
## 73

echo "Search max length of logged string"
# `str` VARCHAR(1024) NOT NULL COMMENT 'строка лога (без временной метки), by default 522'
perl -nE '$a=length;$m=$a if$m<$a;END{say$m-37}' $logFile
## 522

echo "Search max length of address"
# `address` VARCHAR COMMENT 'адрес получателя, by default 39'
perl -naE '$a=length$F[4];$m=$a if$m<$a;END{say$m}' $logFile
## 39

read -s -p "Enter PASSWORD for '$DBname': " pswd

mysql $DBname -p$pswd -u $user < create_meslogDB.sql

exit 0

