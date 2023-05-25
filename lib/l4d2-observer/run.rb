module L4D2Observer
  PUTS = Puts.new
  SURVIVOR = Survivor.new

  def self.run
    PUTS.terminal VERSION
    File.open(LOG, 'a') do |log|
      PUTS.log = log
      # Observer spawns the server and procedes to read it's output.
      Observer.new
      # When the server terminates and Observer reads it's last line,
      # we still have to wait for the read lines to be processed, which
      # is done in separate threads.
      Thread.pass while Thread.list.count > 1
    rescue
      PUTS.error 'In main'
    end
  end
end
