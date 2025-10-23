# 执行计划字段 type

## 举例

### 例1: 按主键或唯一索引等值查询, type=CONST

```
explain
select * from student s where id=2015551301
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|s||const|PRIMARY|PRIMARY|4|const|1|100.0||


### 例2: 按照非唯一索引等值查询, type=ref

```sql
explain
select * from student s where s.major=70
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|s||ref|idx_student_major|idx_student_major|4|const|3|100.0||

### 例3: 对可以为null的二级索引进行等值或null查询, type=ref_or_null

```sql
explain
select * from student s where s.major =70 or s.major is null
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|s||ref_or_null|idx_student_major|idx_student_major|5|const|4|100.0|Using index condition|


### 例4: 对索引进行多个区间(in是多个单点区间)的查询, type=range

```sql
explain
select * from student s where s.major in(70, 71)
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|s||range|idx_student_major|idx_student_major|4||5|100.0|Using index condition|

### 例5: 聚簇索引全表扫描, type=ALL
```sql
explain select * from major;
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|major||ALL|||||74|100.0||


### 例6: 聚簇索引全表扫描按id排序, type=index

```sql
explain select * from major order by id;
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|major||index||PRIMARY|4||74|100.0||


### 例7: 查询条件属于某个索引, 但是不满足前缀匹配, 查询结果被这个索引覆盖, type=index

```sql
explain
select student_id, lesson_id
from student_lesson sl  
where lesson_id=1
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|sl||index|student_lesson_student_id_IDX|student_lesson_student_id_IDX|8||4|25.0|Using where; Using index|

### 例8: 优化器考虑使用两个索引, type=index_merge

```sql
explain
select * from student where major=70 or name like '王%'
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|student||index_merge|idx_student_name,idx_student_major|idx_student_major,idx_student_name|5,34||5|100.0|Using sort_union(idx_student_major,idx_student_name); Using where|


### 例9: eq_ref

```sql
explain
select * 
from college c 
inner join major m on c.id =m.id 
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|c||ALL|PRIMARY||||21|100.0||
|1|SIMPLE|m||eq_ref|PRIMARY|PRIMARY|4|self_exp.c.id|1|100.0||

## 取值和含义

### 例1: const

* 指通过主键或者唯一索引等值访问, 时间性能消耗只需要常数级的, 只需要常数级的时间, 所以称为const

### 例2: ref

* 使用非唯一索引进行等值查询时, 先确定一个二级索引左右相等的闭区间
* 从二级索引的闭区间扫描可以得到多条主键
* 对主键进行回表查询, 得到多条数据范围给用户
* 当进行连接查询时, 访问被驱动表的数据时使用普通二级索引进行查询, 访问被驱动表的方式也称为ref
  * 只是这时会对驱动表扇出的多条数据进行多次查询

### 例3: ref_or_null

* 其他类似于ref的索引访问, 只是查询条件多了 or 索引列 is null
 * 索引中null在树的最左边 

### 例9: eq_ref

* 当使用连接查询时选择的驱动表扇出数据后, 使用非null唯一索引/主键访问被驱动表的数据时, 访问被驱动表的方式称为eq_ref

### 例4: range

* 扫描区间为多个单点扫描区间或者包含一个范围扫描区间

### fulltext

* 全文索引

### 例6/例7: index

* 查询结果的列可以被某个二级索引覆盖, 查询条件只有这个索引相关字段, 但是不满足复合索引的最左匹配原则, 优化器决定使用这个二级索引进行全表扫描
  * 对聚簇索引全表扫描并且按id排序type也是index

### 例8: index_merge

* 索引合并, 详见[索引合并相关笔记](../../Innodb索引/5%20联合索引OR索引合并.md)

### unique_subquery

* 类似于两表连接的eq_ref, 优化器决定将in的相关子查询转换为exists查询, 转换后的exists可以按照主键/非null唯一索引进行查询

### index_subquery

* 类似于unique_subquery, 只是转化后子查询使用的索引是普通二级索引

### system

* 当一个表使用的memory/myisam等统计数据为精确的存储引擎, 并且只有一条数据, 执行全表查询就会显示system

### 例5: all

* 全表扫描

