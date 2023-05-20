module L4D2Observer
class Puts
  attr_writer :terminal, :console, :log

  def initialize
    @terminal = $stdout
    @console = nil
    @log = nil
  end

  using Rainbow

  TX = Mutex.new

  def terminal(string, c = :black)
    TX.synchronize{ @terminal.puts string.color c }
  end

  CX = Mutex.new

  def console(string)
    terminal string, :green
    CX.synchronize{ @console.puts string }
  end

  LX = Mutex.new

  def log(string)
    LX.synchronize{ @log.puts string }
  end

  def error(string, c = :magenta)
    # n is the first 3 line numbers of the backtrace
    n = $!.backtrace[0..2].map{_1.split(':')[1]}.join(',')
    k = $!.class.to_s
    m = $!.message
    message = "# #{k} #{string}(#{n}): #{m}"
    terminal message, c
    log message
  end
end
end
