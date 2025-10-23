# 执行计划字段 select_type

## 举例

### 例1: 查询2015年入学学生的课程修学记录

```sql
explain select sl.* from student s inner join student_lesson sl on s.id =sl.student_id where s.school_year=2015
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|s||ALL|PRIMARY||||5|20.0|Using where|
|1|SIMPLE|sl||ref|student_lesson_student_id|student_lesson_student_id|4|self_exp.s.id|2|100.0||


### 例2: 查询下属专业中存在名称包含'管理'关键字的学院

```sql
 select *
 from college c 
 where exists ( 
    select * from major m 
    where c.id =m.college_id 
    and m.name like '%管理%'
    )
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|<subquery2>||ALL||||||100.0||
|1|SIMPLE|c||eq_ref|PRIMARY|PRIMARY|4|<subquery2>.college_id|1|100.0||
|2|MATERIALIZED|m||ALL|idx_major_college_id||||74|11.11|Using where|

### 例3: UNION ALL

```sql
explain (
select * from college c where c.name like '%物理%'
)
union all (
select * from college c where c.name like '%计算%'
)
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|PRIMARY|c||ALL|||||21|11.11|Using where|
|2|UNION|c||ALL|||||21|11.11|Using where|


### 例4: UNION 

```sql
explain (
select * from college c where c.name like '%物理%'
)
union (
select * from college c where c.name like '%计算%'
)
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|PRIMARY|c||ALL|||||21|11.11|Using where|
|2|UNION|c||ALL|||||21|11.11|Using where|
|3|UNION RESULT|<union1,2>||ALL|||||||Using temporary|

### 例5: 查询先于自己归属学院成立的专业(相关子查询)

```sql
explain
select *
from major m 
where m.establish_year > (
    select c.establish_year  from college c where c.id=m.college_id 
)
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|PRIMARY|m||ALL|||||74|100.0|Using where|
|2|DEPENDENT SUBQUERY|c||eq_ref|PRIMARY|PRIMARY|4|self_exp.m.college_id|1|100.0||


### 例6: 查询早于某个学院成立时间的专业(无关子查询)

```sql
explain
select *
from major m 
where m.establish_year > (
select c.establish_year  from college c where c.id=123
)
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|PRIMARY|m||ALL|||||74|33.33|Using where|
|2|SUBQUERY|c||const|PRIMARY|PRIMARY|4|const|1|100.0||

### 例7: 查询包含计算机相关专业或者成立与1949年前的专业的学院信息

```sql
explain
select *
from college c 
where c.id in (
select m1.college_id from major m1 where m1.establish_year < 1949  union all select m2.college_id from major m2 where m2.name like '%计算机%' 
)
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|PRIMARY|c||ALL|||||21|100.0|Using where|
|2|DEPENDENT SUBQUERY|m1||ref|idx_major_college_id|idx_major_college_id|4|func|3|33.33|Using where|
|3|DEPENDENT UNION|m2||ref|idx_major_college_id|idx_major_college_id|4|func|3|11.11|Using where|

### 例8: 查询各学院的专业数量

```sql
explain
select c.*, temp.cnt
from college c inner join (
select m.college_id, count(*) cnt
from major m 
group  by m.college_id 
) temp on c.id=temp.college_id
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|---|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|PRIMARY|<derived2>||ALL|||||74|100.0||
|1|PRIMARY|c||eq_ref|PRIMARY|PRIMARY|4|temp.college_id|1|100.0||
|2|DERIVED|m||index|idx_major_college_id|idx_major_college_id|4||74|100.0|Using index|


## 取值和含义

### SIMPLE 

* 没有Union或子查询的查询都是Simple

### PRIMARY

* 对于包含UNION(例4)/UNION ALL(例3)/子查询(例5)的大查询是由多个查询组成的, 最大的查询的select_type就是primary
  * 子查询不绝对会有PRIMARY, 得看执行器的优化逻辑, 例5是使用的相关子查询

### UNION

* 对于使用UION/UNION ALL的查询来说, 需要把多个查询的结果集合并起来

### UNION RESULT

* Mysql的UNION 需要使用临时表来进行一次去重, 这一步对应的就是UNION RESULT这一行

### SUBQUERY(例6)

* 如果查询有无关子查询, 并且优化器没有转换为半连接, 无关子查询的类型就是SUBQUERY

### DEPENDENT SUBQUERY(例5)

* 如果查询有相关子查询, 并且不能转换为半连接形式, 则该相关子查询就是EPENDENT SUBQUERY
  * 相关子查询可能会执行很多次, 有可能外层表扫描一次, 内层表执行一次

### DEPENDENT UNION

* 例7中外层查询依赖于内层的两个子查询的Union结果

### DRIVED 

* 例8中的子查询需要将结果生成一个物化表进行连表查询, 这个子查询的类型就是DRIVED

### MATERIALIZED

* 如例2: 优化器决定将子查询结果物化之后与外层进行连接查询, 内层的子查询类型就是MATERIALIZED