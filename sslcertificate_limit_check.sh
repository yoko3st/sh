#!/bin/sh
#
# sslcertificate_limit_check.sh
#
# Description:
#   監視対象のSSL証明書の有効期限を監視する。
#   SSL証明書有効期限が指定された日付前だった場合に
#   第一引数のメールアドレスに対象ドメイン名を送信する。
#   監視対象はリストに記載して第二引数としてシェルに引き渡す。
#   監視対象リストの書式は下記の通り。
#   監視対象ホスト名△FQDN(任意)
#   例) www.google.com www.google.co.jp
#   ※FQDNは接続する際に使用するホスト名と確認したいSSL証明書のFQDNが違う場合に使う。
#     指定されていなければ、ホスト名のSSL証明書を確認する。
#
# Lang:
#   UTF-8
#
# Caution:
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#   第二引数(必須) 監視対象リスト
#
# Create 2017/04/27 yoko3st@gmail.com
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
openssl
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

# 監視対象リストを読み込んで、チェックループ開始
grep -v -e "^#" -e "^$" $2 | while read HOST_NAME FQDN_NAME
do
  # FQDNが指定されていなければ、ホスト名を使用する
  FQDN_NAME=${FQDN_NAME:-${HOST_NAME}}

  # ドメイン名から一時ファイルを指定
  TMP_FILE=${TMP_DIR}/${FQDN_NAME}_`date +%Y%m%d%H%M%S`.tmp

  # opensslコマンドで証明書を取得し、成功した場合は有効期限を確認する
  openssl s_client -connect ${HOST_NAME}:443 -servername ${FQDN_NAME} < /dev/null > $TMP_FILE ; OPENSSL_RCD=$?
  if [ ${OPENSSL_RCD} -eq 0 ]; then
    EXPIRATION_DATE=`openssl x509 -text -noout -in $TMP_FILE | grep "Not After :" | cut -d: -f 2- | xargs -i date +%Y%m%d -d {}`

    # 有効期限をチェックする
    for CHK_DATE in ${CHK_DATE_ARRAY[@]}
    do
      if [ `date +%Y%m%d -d "${CHK_DATE} day"` = ${EXPIRATION_DATE} ]; then
        echo "${FQDN_NAME}のSSL証明書有効期限が残り${CHK_DATE}日です。" | mail -s "SSL証明書有効期限通知：${DOMAIN_NAME} 残り${CHK_DATE}日" $1
      fi
    done
  else
    mail -s "${FQDN_NAME}のSSL証明書有効期限確認に失敗" $1
  fi

  # FQDN_NAME変数を初期化
  unset FQDN_NAME

done

