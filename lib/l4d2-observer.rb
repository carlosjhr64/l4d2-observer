### Standard Library ###
require 'pty'
require 'yaml'
### Gems ###
require 'rainbow/refinement'
### local ###
require_relative 'l4d2-observer/puts.rb'
require_relative 'l4d2-observer/survivor.rb'
require_relative 'l4d2-observer/observer.rb'

module L4D2Observer
  VERSION = '0.1.210622'

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
