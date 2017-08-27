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
# Update 2016/05/22 yoko3st@gmail.com コマンドチェック追加、TMPファイルの個別化、監視対象リストのコメントアウト・空行を無視、wget失敗を検知、その他軽微な修正を実施した
# Update 2016/09/04 yoko3st@gmail.com 日本語URLをメール転送時にデコードするように修正。併せてnkfコマンド有無チェックも追加
# Update 2016/09/10 yoko3st@gmail.com livetubeでは配信URLに全角スペースも含めるが、日本語にURLをデコードすると当然全角スペースになる。それをメール本文で送信してもメーラーでURLの続きとは認識されない。なので、メール本文はデコード前にして件名にデコード済みのURLをつけることで配信タイトルを分かり易くした。ついでにwgetコマンドをやめて、最小限インストールでも入るcurlコマンドに変えた。
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
nkf
CMD_NAME_LIST

# TMPディレクトリがなければ作成
TMP_DIR=/tmp/${SH_NAME} ; [ -d $TMP_DIR ] || mkdir $TMP_DIR

# 監視対象一覧読み込んで、チェックループ開始
grep -v -e "^#" -e "^$" $2 | while read HAI_NAME HAI_LINK
do
  # 配信者名から一時ファイルを指定
  TMP_FILE=${TMP_DIR}/${HAI_NAME}.tmp

  # curlにて配信者ページを取得し、最新の配信リンクだけ抜き出す。curl失敗時はスキップする。
  curl -k -s ${HAI_LINK} | grep -A 8 "コメント" | tail -1 > $TMP_FILE
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "" | mail -s "${HAI_NAME}の配信チェックに失敗" $1
    continue
  fi

  diff $TMP_FILE $TMP_FILE.old ; DIF_RCD=$?
  if [ $DIF_RCD -eq 1 ]; then
    HONBUN=`expr "\`cat $TMP_FILE\`" : "..........\(.*\)..."`
    SUBJECT="${HAI_NAME}が`echo $HONBUN | cut -d/ -f 3 | nkf -w --url-input`を配信"
    echo  http://livetube.cc$HONBUN | mail -s ${SUBJECT} $1
  fi
  cat $TMP_FILE > $TMP_FILE.old
done
