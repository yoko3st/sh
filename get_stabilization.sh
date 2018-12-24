#!/bin/sh
#
# get_stabilization.sh
#
# Description:
#   日本取引所グループサイトの安定操作等ページを取得して更新があれば
#   第一引数のメールアドレスに送信する。
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#
# Create 2018/12/24 yoko3st@gmail.com
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

# メールボディおよび一時ファイル名設定
MAIL_BODY_FILE=/${TMP_DIR}/${SH_NAME}_mail_body
TMP_FILE=/${TMP_DIR}/${SH_NAME}.lst-`date +%Y%m%d%H%M%S`

# Webスクレイピング
wget -q -O - https://www.jpx.co.jp/markets/public/stabilization/ | grep rowspan | awk -F'[><]' '{print $3}' > ${TMP_FILE}

# diff差分確認
diff $TMP_FILE /${TMP_DIR}/${SH_NAME}.lst ; DIF_RCD=$?
  if [ $DIF_RCD -eq 1 ]; then
    echo "下記銘柄に安定操作が行われました" > ${MAIL_BODY_FILE}
    diff  --new-line-format='%L' --unchanged-line-format='' /${TMP_DIR}/${SH_NAME}.lst ${TMP_FILE} >> ${MAIL_BODY_FILE} 
    cat ${MAIL_BODY_FILE} | mail -s "安定操作が行われました" $1
  fi

# TMP_FILE初期化
cat ${TMP_FILE} > /${TMP_DIR}/${SH_NAME}.lst

