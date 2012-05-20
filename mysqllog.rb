# -*- coding: utf-8 -*-

require 'cgi'
require 'erb'
require 'yaml'

require './mysql_log_util'

def abs_path(file)
  app_home = File.dirname(File.expand_path($0))
  File.join(app_home, file)
end

def do_GET(cgi)
  conf = YAML.load_file(abs_path("conf.yaml"))
  t0 = Time.now

  log_path = if cgi["log_path"].empty?
               conf["log_path"]
             else
               cgi["log_path"]
             end
  logs = MysqlLogUtil.parse(log_path, conf["log_size"])

  sec_to_parse = Time.now - t0

  binding
end

def main(cgi)
  begin
    _binding = do_GET(cgi)
    template = File.read(abs_path("mysqllog.erb"))
    ERB.new(template).result(_binding)
  rescue => e
    pre_text = [e.class, e.message, e.backtrace.join("\n")].join("\n----\n")
    "<pre>#{pre_text}</pre>"
  end
end

cgi = CGI.new('html3')
cgi.out { main(cgi) }
