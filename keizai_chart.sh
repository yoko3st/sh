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
# Update 
#
#################################################

# 固定変数
export LANG=ja_JP.utf8
MAIL_BODY_FILE=/tmp/keizai_chart_mail_body-`date +%Y%m%d%H%M%S`

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
