# 执行计划字段分析7: rows和filtered

## 举例

```sql
explain
select * from student_lesson sl   where student_id=2015551301;
```

|id|select_type|table|partitions|type|possible_keys|key|key_len|ref|rows|filtered|Extra|
|--|-----------|-----|----------|----|-------------|---|-------|---|----|--------|-----|
|1|SIMPLE|sl||ref|student_lesson_student_id_IDX|student_lesson_student_id_IDX|4|const|2|100.0||

## rows

* rows是在查询优化器确定使用的索引之后在索引上进行范围扫描的扫描条数

## filtered

* 估算扫描范围内的数据有多大比例符合其他搜索条件
  