#!/bin/sh
#
# livetube_kanshi.sh
#
# Description:
#   livetubeの配信情報を監視して配信があれば
#   第一引数のメールアドレスに送信する。
#   監視対象はリストに記載して第二引数としてシェルに引き渡す。
#   監視対象リストの書式は下記の通り。
#   配信者名△配信者の配信動画ページ
#   例) さんだる http://livetube.cc/%E3%81%95%E3%82%93%E3%81%A0%E3%82%8B
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#   第二引数(必須) 監視対象リスト
#
# Create 2015/05/22 yoko3st@gmail.com
# Update 2015/05/28 yoko3st@gmail.com 監視対象リストを第二引数にした
#
#################################################

# 固定変数
export LANG=ja_JP.utf8

# 監視対象一覧読み込み
while read LINE
do
  TMP_FILE=/tmp/livetube_kanshi_`echo $LINE | awk '{print $1}'`.tmp
  wget -q -O - `echo $LINE | awk '{print $2}'` | grep -A 8 "コメント" | tail -1 > $TMP_FILE

  diff $TMP_FILE $TMP_FILE.old ; DIF_RCD=$?
  if [ $DIF_RCD -eq 1 ]; then
    SUBJECT="`echo $LINE | awk '{print $1}'`の配信を確認"
    HONBUN=`expr "\`cat $TMP_FILE\`" : "..........\(.*\)..."`
    echo  http://livetube.cc$HONBUN | mail -s ${SUBJECT} $1
  fi
  cat $TMP_FILE > $TMP_FILE.old
done < $2

