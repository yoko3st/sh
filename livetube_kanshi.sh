#!/bin/sh
#
# livetube_kanshi.sh
#
# Description:
#   livetubeの配信情報を監視して配信があれば
#   第一引数のメールアドレスに送信する。
#   監視対象は同フォルダのlivetube_kanshi.list.txtに記載する。
#   livetube_kanshi.list.txtの書式は下記の通り。
#   配信者名△配信者の配信動画ページ
#   ＃△は半角スペース
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#
# Create 2015/05/22 yoko3st@gmail.com
# Update
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
done < /home/s-yokoyama/sh/livetube_kanshi.list.txt

