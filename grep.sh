#!/bin/sh
#
# grep.sh
#
# Description:
#   特定フォルダの文字列をgrepする。
#   対象文字列はリストに記載する。
#   リストの場所は引数で引き渡す。
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) grep対象フォルダ
#   第二引数(必須) grep文字列リスト
#   第三引数(任意) grep結果出力先
#
# Create 2017/08/27 yoko3st@gmail.com
#
#################################################

# シェル名設定
SH_NAME=`basename $0 .sh`

# 言語設定
export LANG=ja_JP.utf8

# TMPディレクトリがなければ作成
TMP_DIR=/tmp/${SH_NAME} ; [ -d $TMP_DIR ] || mkdir $TMP_DIR

# ジョブログ設定
LOG_FILE=${TMP_DIR}/${SH_NAME}_`date +%Y%m%d%H%M%S`.log

# 引数確認
echo 引数確認 >> ${LOG_FILE}
echo grep対象フォルダは"${1?第一引数が未定義です。}" >> ${LOG_FILE}
echo grep文字列リストは"${2?第ニ引数が未定義です。}" >> ${LOG_FILE}
OUTPUT_DIR=$3
: ${OUTPUT_DIR:="${TMP_DIR}"}
echo grep結果出力先は"$OUTPUT_DIR"です。 >> ${LOG_FILE}

# ロックファイル確認
LOCK_FILE=${TMP_DIR}/lock.file
if [ -f ${LOCK_FILE} ]; then
  echo 'LOCK FILE exist' > ${LOG_FILE}
  exit 1
else
  date +%Y%m%d%H%M%S > ${LOCK_FILE}
fi

# grep文字列リストを読み込んでループ
cd $1
grep -v -e "^#" -e "^$" $2 | while read LINE
do
  GREP_MOJI=`echo ${LINE} | sed -e "s/[\r\n]\+//g"`
  grep -r $GREP_MOJI $1 > ${OUTPUT_DIR}/$GREP_MOJI.txt
done
> $2

# ロックファイル削除
rm ${LOCK_FILE}
exit 0
