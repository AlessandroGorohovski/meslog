/*
| Create meslogDB
*/

CREATE DATABASE IF NOT EXISTS meslogDB DEFAULT CHARACTER SET = ascii;

USE meslogDB;

DROP TABLE IF EXISTS message; -- удаляем таблицу, если уже существует

CREATE TABLE message (
--	created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL COMMENT 'timestamp строки лога',	-- for Postgresql
	created TIMESTAMP NOT NULL COMMENT 'timestamp строки лога',
	id VARCHAR(128) NOT NULL COMMENT 'значение поля id=xxxx из строки лога, by default 73',
	int_id CHAR(16) NOT NULL COMMENT 'внутренний id сообщения',
	str VARCHAR(1024) NOT NULL COMMENT 'строка лога (без временной метки), by default 522',
	status BOOL,
	CONSTRAINT message_id_pk PRIMARY KEY(id)
) ENGINE = MYISAM COMMENT="for messages with '<=' flag";

CREATE INDEX message_created_idx ON message (created);
CREATE INDEX message_int_id_idx ON message (int_id);

DROP TABLE IF EXISTS log;

CREATE TABLE log (
--	created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL COMMENT 'timestamp строки лога',	-- for Postgresql
	created TIMESTAMP NOT NULL COMMENT 'timestamp строки лога',
	int_id CHAR(16) NOT NULL COMMENT 'внутренний id сообщения',
	flag	ENUM("=>","->","**","==","NA") DEFAULT "NA" NOT NULL,
	str VARCHAR(1024) NOT NULL COMMENT 'строка лога (без временной метки), by default 522',
	address VARCHAR(128) COMMENT 'адрес получателя, by default 39'
) ENGINE = MYISAM COMMENT="for messages without '<=' flag";

-- CREATE INDEX log_address_idx USING HASH ON log (address);	-- for MEMORY table only
CREATE INDEX log_address_idx USING BTREE ON log (address);

