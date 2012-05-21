#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "webrick"
require "yaml"


def mount_by_ext(server, ext)
  Dir.glob("*." + ext){|path|
    server.mount("/"+path, WEBrick::HTTPServlet::FileHandler, path)
  }
end

def print_err(e)
  STDERR.puts e.class, e.message, e.backtrace
end


app_home = File.dirname(File.expand_path(__FILE__))
conf = YAML.load_file(File.join(app_home, "conf.yaml"))

server = WEBrick::HTTPServer.new( :DocumentRoot => app_home,
                                  :BindAddress => '127.0.0.1',
                                  :CGIInterpreter => conf["rubybin"],
                                  :Port => conf["port"] || 8000
                                  )

["mysqllog"].each{|path|
  server.mount( "/" + path,
                WEBrick::HTTPServlet::CGIHandler,
                File.join(app_home, path + ".rb")
                )
}

mount_by_ext(server, "js")
mount_by_ext(server, "css")

%w(HUP INT TERM KILL).each {|signal|
  begin
    Signal.trap(signal){ server.shutdown }
  rescue ArgumentError => e
    print_err(e)
  end
}

server.start
