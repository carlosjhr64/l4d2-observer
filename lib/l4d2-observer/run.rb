module L4D2Observer
  PUTS = Puts.new
  SURVIVOR = Survivor.new

  def self.run
    File.open(LOG, 'a') do |log|
      begin
        PUTS.log = log
        Observer.new
        while Thread.list.count > 1 do
          Thread.pass
        end
      rescue Exception
        PUTS.error 'In main'
      end
    end
  end
end
