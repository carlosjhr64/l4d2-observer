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
    # Specials
    'Boomer'   => true,
    'Charger'  => true,
    'Hunter'   => true,
    'Jockey'   => true,
    'Smoker'   => true,
    'Spitter'  => true,
    'Tank'     => true,
    'Witch'    => true,
  }

  Tally = Struct.new(:ff, :exposure, :pardons, :pity, :kicks, :timestamp, :id) do
    def initialize(ff: 0, exposure: 0, pardons: 0, pity: 0, kicks: 0, timestamp:nil, id: nil)
      super(ff, exposure, pardons, pity, kicks, timestamp, id)
    end
  end

  def initialize
    @active = []
    @players = {}
  end

  def name(id)
    @players.detect{_1[1].id==id}&.first
  end

  def id(name)
    @players[name].id
  end

  def set_id(name, id)
    @players[name].id = id
  end

  def pardons(name)
    @players[name].pardons
  end

  def set_pardons(name, amount)
    @players[name].pardons = bounded amount
  end

  def increment_pardons(name, amount=1)
    set_pardons(name, pardons(name)+amount)
  end

  def decrement_pardons(name, amount=1)
    set_pardons(name, pardons(name)+amount)
  end

  def pity(name)
    @players[name].pity
  end

  def set_pity(name, amount)
    @players[name].pity = bounded amount
  end

  def increment_pity(name, amount=1)
    set_pity(name, pity(name)+amount)
  end

  def timestamp(name)
    @players[name].timestamp
  end

  def set_timestamp(name, time=Time.now)
    @players[name].timestamp = time
  end

  def playtime(name)
    Time.now - @players[name].timestamp
  end

  def active?(name)
    @active.include? name
  end

  def shared_ip?(name)
    if tally = @players[name]
      @names.count{@players[_1]==tally} > 1
    else
      false
    end
  end

  def register!(name, id)
    if active? name then
      if id == id(name)
        false
      else
        # Treat weird name as name change
        return name if name.length > 64 or name.chars.count{_1=~/\w/} < 3
        return name if SURVIVOR.shared_ip?(name)
        set_id(name, id)
        set_timestamp(name)
        true
      end
    else
      name(id) # String | NilClass
    end
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

  def bounded(amount)
    (amount < 0)? 0 : amount
  end

  def kicks(name)
    @players[name].kicks
  end

  def set_kicks(name, amount)
    @players[name].kicks = bounded amount
  end

  def increment_kicks(name, amount=1)
    set_kicks(name, kicks(name) + amount)
  end

  def ff(name)
    @players[name].ff
  end

  def set_ff(name, amount)
    @players[name].ff = bounded amount
  end

  def increment_ff(name, amount=1)
    set_ff(name, ff(name) + amount)
  end

  def decrement_ff(name, amount=1)
    set_ff(name, ff(name) - amount)
  end

  def decrement_ff_for_all(amount=1, except: nil)
    @active.each{|name| decrement_ff(name, amount) unless name == except}
  end

  def exposure(name)
    @players[name].exposure
  end

  def set_exposure(name, amount)
    @players[name].exposure = bounded amount
  end

  def increment_exposure(name, amount=1)
    set_exposure(name, exposure(name)+amount)
  end

  def decrement_exposure(name, amount=1)
    set_exposure(name, exposure(name) - amount)
  end

  def decrement_exposure_for_all(amount=1, except: nil)
    @active.each{|name| decrement_exposure(name, amount) unless name == except}
  end

  def lvp
    @active[-1]
  end

  def mvp
    @active[0]
  end

  def demerits(name)
    (name == mvp)? 2 : 1
  end

  def tallies(attacker, victim)
    increment_ff attacker, demerits(victim)
    increment_exposure victim, demerits(attacker)
  end

  def demote(name)
    if index = @active.index(name) and @active.length > index+1
      @active[index], @active[index+1] = @active[index+1], @active[index]
    end
  end

  def clear_level
    parf = @active.map{|name| @players[name].ff}.minmax.sum{_1.to_i}/2
    parx = @active.map{|name| @players[name].exposure}.minmax.sum{_1.to_i}/2
    @active.each do |name|
      survivor = @players[name]
      survivor.ff = (survivor.ff <= parf)? 0 : survivor.ff - parf
      survivor.exposure = (survivor.exposure <= parx)? 0 : survivor.exposure - parx
    end
  end

  TALLY = {}

  def dump(file)
    File.open(file, 'w'){_1.puts YAML.dump(TALLY)}
  end

  def add(name, ip)
    @active.push name
    @players[name] ||= (TALLY[ip] ||= Tally.new)
  end

  def delete(name)
    @active.delete name
    @players[name].id = nil
  end

  def none?
    @active.empty?
  end

  def names
    @active
  end
end
end
