# 执行计划字段6 ref

## 举例

### 例1: ref为常量值

```sql
explain
select * from student_lesson sl   where student_id=2015551301;
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|sl||ref|student_lesson_student_id_IDX|student_lesson_student_id_IDX|4|const|2|100.0||


### 例2 ref为某一列

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

## 含义

* 当访问type是const, ref, eq_ref, ref, ref_or_null, uniqueue_subquery, index_subquery时, ref列展示的就是和索引列进行等值匹配的是啥字段
  * 可以为某个固定值, 此时显示const
  * 如果是与驱动表扇出的数据匹配, 则展示驱动表扇出的列(库名.表名/查询时的表别名.列名) 
