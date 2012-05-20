# -*- coding: utf-8 -*-

require "../mysql_log_util"

describe MysqlLogUtil do
  describe "parse_rough" do

    describe "log file header + one log" do
      before do

        log_src = <<EOB
/usr/sbin/mysqld, Version: 5.1.61-0ubuntu0.10.10.1-log ((Ubuntu)). started with:
Tcp port: 3306  Unix socket: /var/run/mysqld/mysqld.sock
Time                 Id Command    Argument
		   58 Quit	
EOB

        @rough_logs = MysqlLogUtil.parse_rough(log_src)
      end

      it "should be parsed to 2 raw logs" do
        @rough_logs.size.should == 2
      end
    end

    describe "normal 3 logs" do
      before do

        log_src = <<EOB
		   58 Quit	
120512 12:07:31	   59 Connect	user@localhost on mydb
		   59 Query	select 'foo'
EOB

        @rough_logs = MysqlLogUtil.parse_rough(log_src)
      end

      it "should be parsed to 3 raw logs" do
        @rough_logs.size.should == 3
      end
    end

    describe "normal 4 logs (including Prepare, Execute)" do
      before do

        log_src = <<EOB
		  217 Query	set autocommit=0
		  217 Prepare	insert into items (id, name) values (?, ?)
		  217 Execute	insert into items (id, name) values (1, 'foo')
		  217 Query	select name from table1 where id in (1, 2)
EOB

        @rough_logs = MysqlLogUtil.parse_rough(log_src)
      end

      it "should be parsed to 4 raw logs" do
        @rough_logs.size.should == 4
      end
    end

    # 改行を含むクエリがある3件の場合
    describe "3 logs including query with line break" do
      before do

        log_src = <<EOB
		   60 Query	drop table if exists table1
120512 12:07:32	   60 Query	create table table1 (
  id int
, name varchar(256)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
		   59 Query	select 'foo'
EOB

        @rough_logs = MysqlLogUtil.parse_rough(log_src)
      end

      it "should be parsed to 3 raw logs" do
        @rough_logs.size.should == 3
      end
    end

    describe "blank" do
      before do
        log_src = ""
        @rough_logs = MysqlLogUtil.parse_rough(log_src)
      end

      it "should be pased to 0 logs" do
        @rough_logs.size.should == 0
      end
    end
  end

  describe "parse_fine_each" do
    describe "id + command" do
      before do

        log_line = <<EOB
		   58 Quit	
EOB

        @log = MysqlLogUtil.parse_fine_each([log_line])
      end

      it "should return Log with id and command" do
        @log.id.should == 58
        @log.command.should == "Quit"
        @log.content.should == nil
      end
    end

    describe "id + command + content" do
      before do

        log_line = <<EOB
		   61 Connect	foo@localhost on mydb
EOB

        @log = MysqlLogUtil.parse_fine_each([log_line])
      end

      it "should return Log with id, command and content" do
        @log.id.should == 61
        @log.command.should == "Connect"
        @log.content.should == "foo@localhost on mydb\n"
      end
    end

    describe "datetime + id + command + content" do
      before do

        log_line = <<EOB
120512 12:07:31	   59 Connect	foo@localhost on mydb
EOB

        @log = MysqlLogUtil.parse_fine_each([log_line])
      end

      it "should return Log with datetime, id, command and content" do
        @log.datetime.should == "2012-05-12 12:07:31"
        @log.id.should == 59
        @log.command.should == "Connect"
        @log.content.should == "foo@localhost on mydb\n"
      end
    end
  end
end

