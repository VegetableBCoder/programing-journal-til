# 执行计划字段 id

* 每个select一个唯一id, 如果没有子查询只有一个id, 有子查询则为每一个子查询分配一个id
* union all会有一行udnion记录
  * union需要对结果去重, 因此还会再多一行union_result记录

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

