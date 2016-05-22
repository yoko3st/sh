#!/bin/sh
#
# keizai_chart.sh
#
# Description:
#   各種サイトから日経平均、ドル円、長期金利を取得して
#   第一引数のメールアドレスに送信する。
#   第二引数は任意。メール本文に追加する文字を指定する。
#   グーグルスプレッドのURLなんかつけると便利。
#
# Lang:
#   UTF-8
#
# Argument:
#   第一引数(必須) 送信先メールアドレス
#   第二引数(任意) 任意の文字列
#
# Create 2015/05/22 yoko3st@gmail.com
# Update 2016/05/22 yoko3st@gmail.com コマンドチェック追加、TMPファイルの個別化、その他軽微な修正
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
MAIL_BODY_FILE=/${TMP_DIR}/keizai_chart_mail_body-`date +%Y%m%d%H%M%S`

# 今日日付
echo `date` >> $MAIL_BODY_FILE

# 株価
echo 株価：`wget -q -O - http://stocks.finance.yahoo.co.jp/stocks/detail/?code=998407.o | grep -B 1 zenjituowarine | head -1 | awk '{print substr($0, 43, 9)}'` >> $MAIL_BODY_FILE

# 為替
echo 為替：`wget -q -O - http://info.finance.yahoo.co.jp/fx/detail/?code=USDJPY=FX | grep USDJPY_detail_bid | awk '{print substr($0, 28, 3)}'` >> $MAIL_BODY_FILE

# 長期金利取得
wget -q -O - http://www.bb.jbts.co.jp/_graph/js/long_rate_print.js | sed -e "s/document.write('/長期金利：/" | sed -e "s/');/％/" >> $MAIL_BODY_FILE
echo "" >> $MAIL_BODY_FILE

# スプレッドシートアドレス
echo "" >> $MAIL_BODY_FILE
echo $2 >> $MAIL_BODY_FILE

# メール送信
cat $MAIL_BODY_FILE | mail -s "今日の金融情報" $1
