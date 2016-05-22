#!/bin/sh
#
# domainlimit_check.sh
#
# Description:
#   監視対象のドメインの有効期限を監視する。
#   ドメイン有効期限の指定された日付前だった場合に
#   第一引数のメールアドレスに対象ドメイン名を送信する。
#   監視対象URLはリストに記載して第二引数としてシェルに引き渡す。
#   監視対象ドメインリストの書式は下記の通り。
#   監視対象ドメイン△コメント(任意)
#   例) www.google.co.jp グーグル
#
# Lang:
#   UTF-8
#
# Caution:
#   今のところ対応できているのは.com、.jpのみ。。
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#   第二引数(必須) 監視対象ドメインリスト
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
whois
CMD_NAME_LIST

# 監視タイミングの日付を配列に格納
CHK_DATE_ARRAY=()
CHK_DATE_NUM=0
while read CHK_DATE
do
  CHK_DATE_ARRAY[${CHK_DATE_NUM}]=${CHK_DATE}
  CHK_DATE_NUM=$((CHK_DATE_NUM+1))
done << CHK_DATE_LIST
1
7
30
CHK_DATE_LIST

# TMPディレクトリがなければ作成
TMP_DIR=/tmp/${SH_NAME} ; [ -d $TMP_DIR ] || mkdir $TMP_DIR

# 監視対象一覧を読み込んで、チェックループ開始
grep -v -e "^#" -e "^$" $2 | while read DOMAIN_NAME COMMENT
do
  # ドメイン名から一時ファイルを指定
  TMP_FILE=${TMP_DIR}/${DOMAIN_NAME}_`date +%Y%m%d%H%M%S`.tmp

  # ドメインのTLDを判定し、それぞれのwhois情報を取得する。また、有効期限の記載方法もまちまちなので、整形する。
  case ${DOMAIN_NAME##*.} in
    "com" ) whois ${DOMAIN_NAME} > ${TMP_FILE} || echo "${DOMAIN_NAME}のwhoisに失敗しました。" | mail -s "警告：${SH_NAME}" $1
            EXPIRATION_DATE=`grep "Expiration Date:" ${TMP_FILE} | awk -F'[ T]' '{print $5}'` ;;
    "jp"  ) whois ${DOMAIN_NAME} > ${TMP_FILE} || echo "${DOMAIN_NAME}のwhoisに失敗しました。" | mail -s "警告：${SH_NAME}" $1
            EXPIRATION_DATE=`grep 'Connected (' ${TMP_FILE} | awk -F'[()]' '{print $2}'` ;;
    *     ) echo "${DOMAIN_NAME}は処理できないドメインです。。今のところ対応は.comと.jpだけです。。" | mail -s "警告：${SH_NAME}" $1
            EXPIRATION_DATE='' ;;
  esac

  # 有効期限をチェックする。
  for CHK_DATE in ${CHK_DATE_ARRAY[@]}
  do
    if [ `date +%Y%m%d -d "${CHK_DATE} day"` = `date +%Y%m%d -d "${EXPIRATION_DATE}"` ]; then
      echo "${DOMAIN_NAME}の有効日付が残り${CHK_DATE}日です。" | mail -s "ドメイン有効期限通知：${DOMAIN_NAME} 残り${CHK_DATE}日" $1
    fi
  done

done

