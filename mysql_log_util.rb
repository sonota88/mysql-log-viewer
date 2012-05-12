# -*- coding: utf-8-*-

module MysqlLogUtil
  DATETIME_RE = /\d+ +\d\d?:\d\d:\d\d/
  COMMANDS_RE = /Connect|Query|Quit/
    
  class Log
    attr_accessor :id, :command, :content, :datetime
  end

  def self.parse(path, limit = nil)
    rough_logs = self.parse_rough_file(path, limit)
    self.parse_fine(rough_logs)
  end

  def self.parse_rough_file(path, limit = nil)
    open(path, "r:utf-8"){|fin|
      logs = self.parse_rough(fin, limit)
    }
  end

  def self.parse_rough(input, limit = nil)
    io = case input
         when String
           StringIO.new(input, "r:utf-8")
         else
           input
         end

    logs = []
    buf = []
    while line = io.gets
      if /^(#{DATETIME_RE}|\t)\t\s*(\d+?) (#{COMMANDS_RE})(\t(.+\n))?/m =~ line
        # flush
        logs = self.add_log(logs, buf, limit)
        # next
        buf = [line]
      else
        buf << line
      end
    end
    logs = self.add_log(logs, buf, limit)
    
    logs
  end

  def self.add_log(logs, buf, limit)
    logs << buf if buf != []
    if (not limit.nil?) and logs.size > limit
      logs[-limit..-1]
    else
      logs
    end
  end

  def self.parse_fine(rough_logs)
    logs = []
    rough_logs.each{|rl|
      logs << self.parse_fine_each(rl)
    }

    logs
  end

  def self.parse_fine_each(lines)
    log = Log.new
    first_line = lines[0]

    if /^(#{DATETIME_RE}|\t)\t\s*(\d+?) (#{COMMANDS_RE})(\t(.+\n))?/m =~ first_line
      # typical log
      log.id = $2.to_i
      log.command = $3
      log.content = $5

      if /^(\d\d)(\d\d)(\d\d) +(\d\d?:\d\d:\d\d)/ =~ first_line
        y, m, d, time = $1, $2, $3, $4
        log.datetime = "20%s-%s-%s %s" % [y, m, d, time]
      end

      if lines.size >= 2
        rest = lines[-(lines.size-1)..-1].join("")
        log.content += rest
      end
    else
      # content only
      log.content = lines.join("")
    end
    log
  end
end
