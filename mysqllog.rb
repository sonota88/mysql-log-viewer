# -*- coding: utf-8 -*-

require 'cgi'
require 'erb'
require 'yaml'

require './mysql_log_util'

def abs_path(file)
  app_home = File.dirname(File.expand_path($0))
  File.join(app_home, file)
end

def min_indent(logs)
  min = nil
  logs.each{|log|
    next if log.id.nil?
    min ||= log.id
    min = log.id if log.id < min
  }
  min
end

def do_GET
  conf = YAML.load_file(abs_path("conf.yaml"))
  t0 = Time.now
  logs = MysqlLogUtil.parse(conf["log_path"], conf["log_size"])
  sec_to_parse = Time.now - t0
  min_indent = min_indent(logs)

  binding
end

def main
  begin
    _binding = do_GET
    template = File.read(abs_path("mysqllog.erb"))
    ERB.new(template).result(_binding)
  rescue => e
    pre_text = [e.class, e.message, e.backtrace.join("\n")].join("\n----\n")
    "<pre>#{pre_text}</pre>"
  end
end

cgi = CGI.new('html3')
cgi.out { main }
