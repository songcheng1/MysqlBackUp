
#!/bin/bash
#########################################################################
## Description: Mysql DB的全库备份脚本
## Author: hsc
## mail: hsc@************
## Created Time: 2020年09月01日 10:00:00
##########################################################################
DB_USER='admin'
DATE=`date -d"today" +%Y%m%d`
TIME=`date "+%Y-%m-%d %H:%M:%S"`
echo '--------------开始分库分表备份:开始时间为 '$TIME
for port in `ps -ef | grep mysql| grep socket| grep datadir| awk -F= '{print $NF}'`
  do
    BEGIN=`date "+%Y-%m-%d %H:%M:%S"`
    BEGIN_T=`date -d "$BEGIN" +%s`
    echo '备份'$port'端口号的mysql实例，开始时间为 '$BEGIN
    BACKUP_DIR=/data/backup/$DATE/$port;
    mkdir -p  $BACKUP_DIR;
    ##避免循环的port和sock不匹配
    sock=`ps -ef | grep mysql| grep socket| grep datadir|awk -F".pid" '{print $NF}'| grep $port`
    DB_PASSWORD='123456'
    #过滤掉MySQL自带的DB
    for i in `/usr/local/mysql/bin/mysql -u$DB_USER -p$DB_PASSWORD  $sock -BN -e"show databases;" |sed '/^performance_schema$/'d|sed '/^mysql/'d |sed '/^information_schema$/'d|sed '/^information_schema$/'d|sed '/^test$/'d  `
    do
      sudo  /usr/local/mysql/bin/mysqldump -u$DB_USER -p$DB_PASSWORD $sock --master-data=2 -q  -c  --skip-add-locks  -R -E -B $i > $BACKUP_DIR/$date$i.sql
    done
    END=`date "+%Y-%m-%d %H:%M:%S"`
    END_T=`date -d "$END" +%s`
    TIME_INVENTAL_M=$[($END_T-$BEGIN_T)/60]
    TIME_INVENTAL_S=$[($END_T-$BEGIN_T)%60]
    echo '备份'$port'端口号的mysql实例于' $END '备份完成，使用时间为 '$TIME_INVENTAL_M'分钟'$TIME_INVENTAL_S'秒'
         #备份文件的处理
         cd $BACKUP_DIR/..
         tar -zczf $port'_'$(date +%F_%H-%M).tar.gz $port
         #解压 tar -zvxf  $port.tar.gz
         rm -rf $port
done
TIME_END=`date "+%Y-%m-%d %H:%M:%S"`
echo '--------------backup all database successfully！！！结束时间:' $TIME_END
#删除7天以前的备份
find /data/backup/ -name '*'`date +%Y`'*' -type d -mtime  +7 -exec rm -rf  {} \;


#!/bin/sh
#########################################################################
## Description: Mysql全量备份脚本
## Author: hsc
## mail: hsc@************
## Created Time: 2020年09月01日 10:00:00
##########################################################################
OneMonthAgo=`date -d "2 month ago"  +%Y%m%d`
today=`date +%Y%m%d`
datetime=`date +%Y%m%d-%H-%M-%S`
config=/etc/mykedata_3326.cnf
basePath=/data/backup
logfilePath=$basePath/logs
logfile=$logfilePath/full_$datetime.log
USER=admin
PASSWD=123456
SOCKET=/data/mysqldata/kedata/mysql.sock
dataBases="huoqiu batchdb shenzhen tianjin asset bc_asset shanghai vered_dataplatform aomen"
echo 'Full backup mysql in ' $path > $logfile
path=$basePath/full_$datetime
mkdir -p $path
sudo /usr/bin/innobackupex  --defaults-file=$config  --user=$USER --password=$PASSWD --socket=$SOCKET --compress --compress-threads=2 --compress-chunk-size=64K --host=localhost  $path --no-timestamp  > $logfile 2>&1
#--safe-slave-backup
sudo chown app.app $path -R
ret=`tail -n 2 $logfile |grep "completed OK"|wc -l`
if [ "$ret" =  1 ] ; then
        echo 'delete expired backup ' $basePath/$OneMonthAgo  >> $logfile
        echo $path > $logfilePath/last_backup_sucess.log
        rm -rf $basePath/full_$OneMonthAgo*
        rm -f   $logfilePath/full_$OneMonthAgo*.log
else
  echo 'backup failure ,no delete expired backup'  >> $logfile
fi

if [ "$ret" = 1 ] ;then
    status=0
else
    status=1
fi
echo $status
ts=`date +%s`;
curl -X POST -d "[{\"metric\": \"backup_status\", \"endpoint\": \"bl2-mysql01.veredholdings.cn\", \"timestamp\": $ts,\"step\":86400,\"value\": $status,\"counterType\": \"GAUGE\",\"tags\": \"\"}]" http://127.0.0.1:9982/v1/push


#!/bin/sh
#########################################################################
## Description: Mysql增量备份脚本
## Author: hsc
## mail: hsc@************
## Created Time: 2021年09月01日 10:00:00
##########################################################################
today=`date +%Y%m%d`
datetime=`date +%Y%m%d-%H-%M-%S`
config=/etc/mykedata_3326.cnf
basePath=/data/backup
logfilePath=$basePath/logs
logfile=$logfilePath/incr_$datetime.log
USER=admin
PASSWD=123456
dataBases="huoqiu batchdb shenzhen tianjin shanghai asset aomen"

pid=`ps -ef | grep -v "grep" |grep -i innobackupex|awk '{print $2}'|head -n 1`
if [ -z $pid ]
then
  echo " start incremental backup database " >> $logfile
  OneMonthAgo=`date -d "1 month ago"  +%Y%m%d`
  path=$basePath/incr_$datetime
  mkdir -p $path
  last_backup=`cat $logfilePath/last_backup_sucess.log| head -1`
  echo " last backup is ===> " $last_backup >> $logfile
sudo /usr/bin/innobackupex  --defaults-file=$config  --user=$USER --password=$PASSWD --compress --compress-threads=2 --compress-chunk-size=64K --slave-info  --host=localhost --incremental $path --incremental-basedir=$last_backup --databases="${dataBases}" --no-timestamp >> $logfile 2>&1
#--safe-slave-backup
sudo chown app.app $path -R
  ret=`tail -n 2 $logfile |grep "completed OK"|wc -l`
  if [ "$ret" =  1 ] ; then
    echo 'delete expired backup ' $basePath/incr_$OneMonthAgo*  >> $logfile
    rm -rf $basePath/incr_$OneMonthAgo*
    rm -f $logfilePath/incr_$OneMonthAgo*.log
    echo $path > $logfilePath/last_backup_sucess.log
  else
    echo 'backup failure ,no delete expired backup'  >> $logfile
  fi
else
   echo "****** innobackupex in backup database  ****** "  >> $logfile
fi


#!/bin/bash
USERNAME=admin
PASSWORD=123456
DATE=`date +%Y-%m-%d`
OLDDATE=`date +%Y-%m-%d -d '-30 days'`

MYSQL=/usr/local/mysql/bin/mysql
MYSQLDUMP=/usr/local/mysql/bin/mysqldump
MYSQLADMIN=/usr/local/mysql/bin/mysqladmin
SOCKET=/data/mysqldata/mysql.sock
BACKDIR=/data/backup/

[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}
[ -d ${BACKDIR}/${DATE} ] || mkdir ${BACKDIR}/${DATE}
[ ! -d ${BACKDIR}/${OLDDATE} ] || rm -rf ${BACKDIR}/${OLDDATE}

for DBNAME in anhui huoqiu beijing  shenzhen shanghai tianjin  hsc aomen
do
   ${MYSQLDUMP} --opt -u${USERNAME} -p${PASSWORD} -S${SOCKET} ${DBNAME} | gzip > ${BACKDIR}/${DATE}/${DBNAME}-backup-${DATE}.sql.gz
   logger "${DBNAME} has been backup successful - $DATE"
   /bin/sleep 5
done



#!/bin/bash
datetime=`date +%Y%m%d-%H-%M-%S`
logfile=/data/backup/rsync.log
echo "$datetime Rsync backup mysql start "  >> $logfile
sudo rsync -e "ssh -p6666" -avpgolr /data/backup hsc@192.168.10.169:/data/backup_data/hsc/DB_bak/192.168.10.150/ >> $logfile 2>&1

ret=`tail -n 1 $logfile |grep "total size"|wc -l`
if [ "$ret" =  1 ] ; then
        echo "$datetime Rsync backup mysql finish " >> $logfile
else
        echo "$datetime Rsync backup failure ,pls sendmail"  >> $logfile
fi
