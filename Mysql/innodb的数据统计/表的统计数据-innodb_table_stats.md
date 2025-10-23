# innodb_table_stats

## 字段含义

| 字段                    | 含义                   |
| ----------------------- | ---------------------- |
| database_name           | 数据库名               |
| table_name              | 表名                   |
| last_update             | 最后更新时间           |
| n_rows                  | 表中的记录条数         |
| clustered_index_size    | 聚簇索引占用页面数量   |
| sum_of_other_index_size | 其他索引占用的页面数量 |

## n_rows的统计, 为什么不是准确值

* 统计规则: 从聚簇索引取一定量的页面, 求这些页面记录数的平均值, 然后乘总叶子结点页面数
  

## clustered_index_size/sum_of_other_index_size的统计

* 从sys_index中找到索引的根页面
* 一个索引占用两个段: 非叶子节点段和叶子节点段, 从根页面找到叶子结点的两个段头
* 从段头找到INODE Entry信息
* 从INODE Entry信息找到FREE, FULL, NOT_FULL链表, 从这三个链表的ListLength信息中可以读出该段占用的区数量, 与每个区64页进行运算即可得到页面数
