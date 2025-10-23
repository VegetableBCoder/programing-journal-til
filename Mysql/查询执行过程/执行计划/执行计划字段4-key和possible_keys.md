# key和possible_keys

## 含义解释

* possible_keys是查询条件可能使用到的索引列表
  * possible_keys不是越多越好, 执行器会评估它们的执行成本进行比较, 这一步也会有性能消耗
* key是执行优化器最终选定的索引
