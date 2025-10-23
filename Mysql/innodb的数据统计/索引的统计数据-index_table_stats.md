 # innodb_index_stats

 ## 字段含义

| 字段             | 含义       |
| ---------------- | ---------- |
| database_name    | 数据库名   |
| table_name       | 表名       |
| index_name       | 索引名     |
| last_update      | 更新时间   |
| stat_name        | 统计项名称 |
| stat_value       | 统计值     |
| sample_size      | 采样页面数 |
| stat_description | 统计项描述 |

## 统计项

* n_leaf_pages: 索引在叶子上占用的页面数
* size: 索引占用的页面数(包含分配到段, 但是未使用的空间)
* n_diff_pfx(N): 组合索引前N个Part不重复的记录数

 