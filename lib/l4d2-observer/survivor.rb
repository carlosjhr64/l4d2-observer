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
    @players = [] # Current players
    @tallies = {} # Tally of all players
  end

  def names
    @players
  end

  # Least Valuable Player
  def lvp
    @players.last
  end

  # Most Valuable Player
  def mvp
    @players.first
  end

  def active?(name)
    @players.include? name
  end

  def none?
    @players.empty?
  end

  # Are both players human?
  # If so, return true. If not, return false.
  # But guard against name changes while in game.
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

  # Add a player's name to the game.
  # Set a new player's tally to Tally.new(or existing tally based on ip).
  # Tally[ip] guards against name changes.
  def add(name, ip)
    @players.push name
    @tallies[name] ||= (TALLY[ip] ||= Tally.new)
  end

  # Demoting a player moves the player one position closer to last.
  def demote(demoted)
    return if demoted == @players.last # Can't further demote last player

    index = @players.index(demoted)
    @players[index] = @players[index+1]
    @players[index+1] = demoted
  end

  # Check if a player name is sharing an ip with another player name.
  # It's possible that a player changed their name.
  def shared_ip?(name)
    if (tally = @tallies[name])
      @names.count{@tallies[_1]==tally} > 1
    else
      false
    end
  end

  # getters and setters for Tally attributes
  %w[ff exposure pardons pity kicks timestamp id].each do |attribute|
    define_method attribute do |name|
      @tallies[name].send attribute
    end
    define_method "set_#{attribute}" do |name, value|
      @tallies[name].send "#{attribute}=", value
    end
  end

  # Player has left the game.
  def delete(name, id=nil)
    if @players.include?(name)
      @players.delete name
      set_id(name, nil)
      set_pardons(name, 0)
    elsif id && (name=name(id)) && @players.include?(name)
      @players.delete name
      set_id(name, nil)
      set_pardons(name, 0)
    end
  end

  # Get player's name from id.
  def name(id)
    @tallies.detect{_1[1].id==id}&.first
  end

  def register!(name, id)
    if active? name
      if id == id(name)
        false # Previously registered
      else
        # name issues... will be kicked
        return name unless name.length < 65 &&
                           name=~/^[[:print:]]+$/ &&
                           name.chars.count{_1=~/\w/} > 1
        return name if SURVIVOR.shared_ip?(name)
        return name if BOT[name]
        # name is good
        set_id(name, id)
        set_timestamp name, Time.now
        true # Now registered
      end
    else
      name # Player must have changed name in game. Will be kicked.
    end
  end

  def playtime(name)
    Time.now - timestamp(name)
  end

  def positive(amount)
    amount.negative? ? 0 : amount
  end

  # increment and decrement
  %w[ff exposure pardons pity kicks].each do |attribute|
    define_method "increment_#{attribute}" do |name, amount=1|
      send "set_#{attribute}", name, send(attribute, name)+amount
    end
    define_method "decrement_#{attribute}" do |name, amount=1|
      send "set_#{attribute}", name, positive(send(attribute, name)-amount)
    end
  end

  # decrement for all
  %w[ff exposure pity].each do |attribute|
    define_method "decrement_#{attribute}_for_all" do |amount=1, except: nil|
      @players.each do |name|
        next if name == except
        send "decrement_#{attribute}", name, amount
      end
    end
  end

  # Demerits for offenses against the MVP are doubled.
  def demerits(name)
    name == mvp ? 2 : 1
  end

  # Players are expected to avoid friendly fire and exposure to friendly fire.
  # Too much friendly fire or exposure to friendly fire will result in a kick.
  # Increment the friendly fire count of the attacker.
  # Increment the exposure count of the victim.
  # The MVP is assumed to be playing well, and so demirits for FF to the MVP is
  # doubled, and demerits for exposure to FF from the MVP is doubled.
  def tallies(attacker, victim)
    increment_ff attacker, demerits(victim)
    increment_exposure victim, demerits(attacker)
  end

  # For fairness, when a new player joins, the tallies of players are reduced
  # by a par amount: min.
  def balance_rankings(newcomer)
    parf = names.reject{_1==newcomer}.map{ff _1}.min
    decrement_ff_for_all(parf, except:newcomer)
    parx = names.reject{_1==newcomer}.map{exposure _1}.min
    decrement_exposure_for_all(parx, except:newcomer)
    parp = names.reject{_1==newcomer}.map{pity _1}.min
    decrement_pity_for_all(parp, except:newcomer)
  end

  # After clearing a level, the tallies are reduced by a
  # par amount: (min + max)/2.
  def clear_level
    parf = names.map{ff _1}.minmax.sum/2
    decrement_ff_for_all(parf)
    parx = names.map{exposure _1}.minmax.sum/2
    decrement_exposure_for_all(parx)
    parp = names.map{pity _1}.minmax.sum/2
    decrement_pity_for_all(parp)
  end
end
end
