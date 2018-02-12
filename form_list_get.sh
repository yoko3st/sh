#!/bin/sh
#
# form_list_get.sh
#
# Description:
#   第一引数で指定されたWebページから
#   第二引数で指定されたidを持つForm内の値を取得してリストを作成する。
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) URL
#   第二引数(必須) Formのid
#
# Create 2018/02/12 yoko3st@gmail.com
#
#################################################

# シェル名設定
SH_NAME=`basename $0 .sh`

# 言語設定
export LANG=ja_JP.utf8

# TMPディレクトリがなければ作成
TMP_DIR=/tmp/${SH_NAME} ; [ -d $TMP_DIR ] || mkdir $TMP_DIR

# 主処理
curl -s $1 | \
sed -n "/$2/,/select/p" | \
sed "s|</option>|\n|g" | \
grep option | \
tr '>' '\n' | \
egrep -v "option|select" | \
sort > ${TMP_DIR}/`echo ${1} | awk -F "/" '{ print $NF }'`
