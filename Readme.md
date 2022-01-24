1、查看最大连接数

show variables like '%max_connections%';

2、修改最大连接数

set GLOBAL max_connections = 200;

3、查询连接数量

show processlist;

4、统计本月数据量

select DATE_FORMAT(时间字段,"%Y-%m-%d") 时间字段,COUNT(*) from 表名 where date_format(时间字段,'%Y-%m') = date_format(now(),'%Y-%m') GROUP BY DATE_FORMAT(时间字段,"%y-%m-%d")

5、数据库备份

/usr/local/mysql/bin/mysqldump --all-databases -hlocalhost -uroot -p123456 > /root/allbackupfile.sql
