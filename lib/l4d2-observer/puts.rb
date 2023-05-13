module L4D2Observer
class Puts
  attr_writer :terminal, :console, :log

  def initialize
    @terminal = $stdout
    @console = nil
    @log = nil
  end

  using Rainbow

  def terminal(string, c = :black)
    @terminal.puts string.color c
  end

  CX = Mutex.new

  def console(string)
    terminal string, :green
    CX.synchronize{ @console.puts string }
  end

  def log(string)
    @log.puts string
  end

  def error(string, c = :magenta)
    # n is the first 3 line numbers of the backtrace
    n = $!.backtrace[0..2].map{_1.split(':')[1]}.join(',')
    terminal "### #{string}(#{n}) ###", c
    terminal $!.class.to_s, c
    terminal $!.message, c
  end
end
end
