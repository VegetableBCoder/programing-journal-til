drop table if exists student;
create table student(
  id int not null auto_increment comment '学号',
  name varchar(30) not null comment '姓名',
  school_year int not null comment '入学年份',
  major int not null comment '专业',
  class_no int not null comment '班级号',
  province int not null comment '生源省份',
  primary key(id),
  key idx_student_name(name(8)),
  key idx_student_major(major),
  key idx_student_province(province)
);

drop table if exists college;
create table college(
  id int not null auto_increment,
  name varchar(128) not null,
  description varchar (500) not null default '',
  `establish_year` int NOT NULL DEFAULT '1950',
  primary key(id)
);

drop table if exists major;
create table major(
	id int not null auto_increment,
	name varchar(128) not null,
	college_id int not null,
	`establish_year` int NOT NULL DEFAULT '1950',
	primary key(id),
	key idx_major_college_id(college_id)
);

drop table if exists lesson;
create table lesson (
	id int not null auto_increment,
	name varchar(128) not null,
	type varchar(64) not null,
	primary key(id),
	key idx_lesson_type(`type`(8))
);

drop table if exists `lesson_plan`;
create table lesson_plan (
	id int not null auto_increment,
	major_id int not null comment '专业id',
	lesson_id int not null comment '课程id',
	compulsory tinyint not null comment '是否必修课程', 
	semesternot_index int null comment '学期序号, -1表示自由选修',
	credit tinyint not null comment '学分数',
	primary key(id),
	key idx_lesson_plan_major_id(major_id)
);
drop table if exists `student_lesson`;
create table student_lesson(
	id int not null auto_increment,
	student_id int not null comment '学号',
	type tinyint not null comment '类型: 0: 必修 1: 选修 2: 重修(选修无重修)',
	lesson_id int not null comment '课程id',
	semesternot_no int not null comment '学期号: 前4位为年份, 最后两位表示年内的学期号',
	primary key(id),
	key student_lesson_student_lesson(student_id, lesson_id)
) comment ='修学记录表';

drop table if exists exam_score;
create table exam_score(
	id int not null auto_increment,
	student_lesson_id int not null comment '修学记录id',
	grade decimal(4,1) not null comment '成绩',
	make_up_grade decimal(4,1) not null comment '补考成绩',
	primary key(id),
	key exam_score_student_lesson(student_lesson_id)
);


drop table if exists region;
create table region(
	id int not null auto_increment,
	name varchar(128) not null,
	country varchar(128) not null,
	country_coude varchar(3) not null,
	primary key(id)
);


drop table if exists user_cuppon;
create table user_cuppon(
	id int not null auto_increment,
	user_id int not null comment '用户id',
	cuppon_id int not null  comment '优惠券id',
	`begin` timestamp not null comment '可用时间 开始时间',
	`end` timestamp not null comment '可用时间 结束时间',
	`type` tinyint not null comment '优惠券类型',
	`get_at` timestamp not null comment '领券时间',
	primary key (id),
	key idx_user_cuppon_user_time(user_id, `end`, `begin`),
	key idx_user_cuppon_cuppon_id(cuppon_id)
);
