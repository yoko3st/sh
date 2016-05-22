#!/bin/sh
#
# website_kanshi.sh
#
# Description:
#   指定のWEBサイトを監視して問題があれば
#   第一引数のメールアドレスに送信する。
#   監視対象URLはリストに記載して第二引数としてシェルに引き渡す。
#   監視対象リストの書式は下記の通り。
#   プロトコル△URL
#   例) http www.google.co.jp
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#   第二引数(必須) 監視対象リスト
#
# Create 2016/05/22 yoko3st@gmail.com
#
#################################################

# シェル名設定
SH_NAME=`basename $0 .sh`

# 言語設定
export LANG=ja_JP.utf8

# コマンドチェック
while read CMD_NAME
do
  if [ ! `which ${CMD_NAME}` ]; then
    echo "${CMD_NAME}コマンドが存在しないため、処理を異常終了します。" | mail -s "異常終了：${SH_NAME}" $1
    exit 1
  fi
done << CMD_NAME_LIST
wget
CMD_NAME_LIST

# TMPディレクトリがなければ作成
TMP_DIR=/tmp/${SH_NAME} ; [ -d $TMP_DIR ] || mkdir $TMP_DIR

# 監視対象一覧を読み込んで、チェックループ開始
grep -v -e "^#" -e "^$" $2 | while read LINE
do
  TMP_FILE=${TMP_DIR}/`echo $LINE | awk '{print $2}' | sed 's|/|_|g'`_`date +%Y%m%d%H%M%S`.tmp
  wget --spider -nv --timeout 20 -t 3 `echo $LINE | awk '{print $1}'`://`echo $LINE | awk '{print $2}'` > ${TMP_FILE} 2>&1
  grep '200 OK' ${TMP_FILE}  ; GREP_RCD=$?
  if [ $GREP_RCD -ne 0 ]; then
    SUBJECT="`echo $LINE | awk '{print $2}'`のダウンを確認"
    echo `echo $LINE | awk '{print $1}'`://`echo $LINE | awk '{print $2}'` | mail -s ${SUBJECT} $1
  fi
done

