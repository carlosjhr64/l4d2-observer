module L4D2Observer
class Survivor
  BOT = {
    # L4D1
    'Bill'     => true,
    'Francis'  => true,
    'Louis'    => true,
    'Zoey'     => true,
    # L4D2
    'Coach'    => true,
    'Ellis'    => true,
    'Nick'     => true,
    'Rochelle' => true,
  }

  TALLY = {}

  Tally = Struct.new(:ff, :exposure, :pardons, :pity, :kicks,
                     :timestamp, :id) do
    def initialize(ff:0, exposure:0, pardons:0, pity:0, kicks:0,
                   timestamp:nil, id:nil)
      super(ff, exposure, pardons, pity, kicks, timestamp, id)
    end
  end

  def dump(file)
    File.open(file, 'w'){_1.puts YAML.dump(TALLY)}
  end

  def initialize
    @active = []
    @players = {}
  end

  def names
    @active
  end

  def lvp
    @active[-1]
  end

  def mvp
    @active[0]
  end

  def active?(name)
    @active.include? name
  end

  def none?
    @active.empty?
  end

  def pvp?(attacker, victim)
    if active? attacker
      if active? victim
        true
      elsif BOT[victim]
        false
      else
        # Name must have changed!
        victim
      end
    else
      # BOT never reported as attacker,
      # name must have changed!
      attacker
    end
  end

  def add(name, ip)
    @active.push name
    @players[name] ||= (TALLY[ip] ||= Tally.new)
  end

  def demote(name)
    if (index = @active.index(name)) && @active.length > index+1
      @active[index], @active[index+1] = @active[index+1], @active[index]
    end
  end

  def shared_ip?(name)
    if (tally = @players[name])
      @names.count{@players[_1]==tally} > 1
    else
      false
    end
  end

  # get and set
  %w[ff exposure pardons pity kicks timestamp id].each do |attribute|
    define_method attribute do |name|
      @players[name].send attribute
    end
    define_method "set_#{attribute}" do |name, value|
      @players[name].send "#{attribute}=", value
    end
  end

  def delete(name)
    @active.delete name
    set_id(name, nil)
    set_pardons(name, 0)
  end

  def name(id)
    @players.detect{_1[1].id==id}&.first
  end

  def register!(name, id)
    if active? name
      if id == id(name)
        false
      else
        # name issues...
        return name unless name.length < 65 &&
                           name=~/^[[:print:]]+$/ &&
                           name.chars.count{_1=~/\w/} > 1
        return name if SURVIVOR.shared_ip?(name)
        return name if BOT[name]
        set_id(name, id)
        set_timestamp name, Time.now
        true
      end
    else
      name(id) # String | NilClass
    end
  end

  def playtime(name)
    Time.now - timestamp(name)
  end

  def no_less_than_zero(amount)
    amount.negative? ? 0 : amount
  end

  # increment and decrement
  %w[ff exposure pardons pity kicks].each do |attribute|
    define_method "increment_#{attribute}" do |name, amount=1|
      send "set_#{attribute}", name, send(attribute, name)+amount
    end
    define_method "decrement_#{attribute}" do |name, amount=1|
      send "set_#{attribute}", name,
        no_less_than_zero(send(attribute, name)-amount)
    end
  end

  # decrement of all
  %w[ff exposure pity].each do |attribute|
    define_method "decrement_#{attribute}_for_all" do |amount=1, except: nil|
      @active.each do |name|
        next if name == except
        send "decrement_#{attribute}", name, amount
      end
    end
  end

  def demerits(name)
    name == mvp ? 2 : 1
  end

  def tallies(attacker, victim)
    increment_ff attacker, demerits(victim)
    increment_exposure victim, demerits(attacker)
  end

  def balance_rankings(newcomer)
    parf = names.reject{_1==newcomer}.map{ff(_1)}.min
    decrement_ff_for_all(parf, except:newcomer)
    parx = names.reject{_1==newcomer}.map{exposure(_1)}.min
    decrement_exposure_for_all(parx, except:newcomer)
    parp = names.reject{_1==newcomer}.map{pity(_1)}.min
    decrement_pity_for_all(parp, except:newcomer)
  end

  def clear_level
    parf = names.map{|name| ff(name)}.minmax.sum(&:to_i)/2
    parx = names.map{|name| exposure(name)}.minmax.sum(&:to_i)/2
    names.each do |name|
      ff = ff(name)
      set_ff(name, ff <= parf ? 0 : ff - parf)
      exposure = exposure(name)
      set_exposure(name, exposure <= parx ? 0 : exposure - parx)
    end
  end
end
end
