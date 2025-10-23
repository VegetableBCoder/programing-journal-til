## 执行计划字段分析8: extra

## 例1: No table used

```
explain select now()
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE||||||||||No tables used|


### 分析

* 这个sql与数据库表无关, 所以显示No tables used

## 例2: Impossible where

```sql
explain select * from lesson l where 1=0
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE||||||||||Impossible WHERE|

### 分析

* 查询条件不可能成立, 所以显示Impossible WHERE

## 例3: No matching row

```
explain select max(credit) from lesson_plan where id=0 
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE||||||||||no matching row in const table|

### 说明

* 当使用聚合函数时, 但是没有符合搜索条件的row

## 例4: Using index

```sql
explain
select  begin, end
from user_cuppon uc 
where user_id= 1
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|uc||ref|idx_user_cuppon_user_time|idx_user_cuppon_user_time|4|const|3|100.0|Using index|


### 说明

* 当查询能使用到索引覆盖无需回表时, 显示using index

## 举例4 using_index_condition

```sql
explain
select *
from user_cuppon uc 
where user_id= 1 and begin < '2025-11-01 00:00:00'
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|uc||ref|idx_user_cuppon_user_time|idx_user_cuppon_user_time|4|const|3|33.33|Using index condition|

### 说明

* Using index condition表示使用了索引条件下推, 详见[相关笔记](../../Innodb索引/6%20索引条件下推.md)

## 举例: using where

```
explain
select  begin, end
from user_cuppon uc 
where user_id= 1 and begin < '2025-11-01 00:00:00'
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|uc||ref|idx_user_cuppon_user_time|idx_user_cuppon_user_time|4|const|3|33.33|Using where; Using index|


### 说明

* 从存储引擎层取出数据后需要在server层判断是否符合where条件
  * using where并不意味着回表 索引覆盖的情况下查询条件的其他列也在这个也在这个索引的内容中, 只是无法形成扫描区间, 从存储引擎取出后还需要判断一下是否符合条件, 如果判断之后还需要回表就是索引条件下推
    * 比如举例的sql, 如果改为select * 就是索引下推, 但是从聚簇索引取数据只需要再判断条件, 所以执行计划不显示using where
  
### 举例: zero limit

```
explain select * from student limit 0
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE||||||||||Zero limit|

### 说明

* 由于limit的条数是0, server层不会真正调用存储引擎层取数据, 而是快速返回


## 举例: Using file sort

```sql
explain select * from student order by school_year
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|student||ALL|||||17|100.0|Using filesort|

### 说明

* school_year没有索引, 因此需要在内存/磁盘中排序

## in 子查询相关

* 详见[子查询优化](../查询优化器-部分优化规则/子查询优化.md)的in子查询优化部分

### Start/End temporary

* mysql针对in子查询的执行策略, 将子查询转换为半连接, 策略为 Duplicate Weedout(重复)时显示Start/end Temporary

### LooseScan

* in 子查询的LoosScan(松散扫描)执行策略,

### FirstMatch(表名)

* in 子查询的执行策略为FirstMatch(首次匹配) 策略