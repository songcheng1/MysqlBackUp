1、查看最大连接数

show variables like '%max_connections%';

2、修改最大连接数

set GLOBAL max_connections = 200;

3、查询连接数量
show processlist;
