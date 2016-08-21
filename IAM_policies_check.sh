#!/bin/sh
#
# IAM_policies_check.sh
#
# Description:
#   IAMのポリシー一覧を監視し、変更があれば
#   第一引数のメールアドレスに送信する。
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#
# Create 2016/08/20 yoko3st@gmail.com
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
js-beautify
jq
CMD_NAME_LIST

# TMPディレクトリがなければ作成
TMP_DIR=/tmp/${SH_NAME} ; [ -d $TMP_DIR ] || mkdir $TMP_DIR

# IAMポリシー一覧を取得して、js-beautifyコマンドで整形
curl https://awsiamconsole.s3.amazonaws.com/iam/assets/js/bundles/policies.js | js-beautify | \
# PolicyEditorConfig以下を抜き出す
sed -ne '/PolicyEditorConfig/,$p' > $TMP_DIR/policies.tmp
# js-beautifyコマンドから直接パイプしてgrepするとエラーになるので、一度ファイル出力したものをgrepしてAWSサービスとIAMポリシーを抜き出す
egrep '": {|Actions:' $TMP_DIR/policies.tmp > $TMP_DIR/policies.txt

# AWSサービス毎にポリシー一覧を作成して前回のファイルとdiff差分があればメールする
grep -v "Actions:" $TMP_DIR/policies.txt | cut -d\" -f2 | while read AWS_Service
do
  AWS_SW_NAME=`echo $AWS_Service | sed -e "s/ //g"`
  OLD_FILE=${TMP_DIR}/${AWS_SW_NAME}.txt
  TMP_FILE=${TMP_DIR}/${AWS_SW_NAME}_`date +%Y%m%d%H%M%S`.tmp
  grep -A 1 "${AWS_Service}" $TMP_DIR/policies.txt | tail -1 | cut -d: -f2 | sed -e "s/],/]/g" | jq '.' > ${TMP_FILE}
  if [ -e ${OLD_FILE} ]; then
    diff -u ${OLD_FILE} ${TMP_FILE} > ${TMP_DIR}/${AWS_SW_NAME}_MAILHONBUN.txt ; DIFF_RCD=$?
    if [ $DIFF_RCD -ne 0 ]; then
      SUBJECT="${AWS_SW_NAME}のポリシー更新を確認"
      cat ${TMP_DIR}/${AWS_SW_NAME}_MAILHONBUN.txt | mail -s ${SUBJECT} $1
    fi
  fi
  cat ${TMP_FILE} > ${OLD_FILE}
done
