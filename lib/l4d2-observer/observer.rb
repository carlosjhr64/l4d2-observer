module L4D2Observer
class Observer
  SURVIVOR = Survivor.new

  # Server is able to display messages to all players via the 'say' command.
  def say(string)
    "say  #{string}"
  end

  def fix(name)
    display = name.gsub(/\W+/, X)
    if display.length > 14
      display = display.gsub(X, '')
      display = display[0...13]+X if display.length > 14
    end
    display
  end

  # Every time rankings change,
  # the server displays the new rankings to all players.
  def rankings
    number = 0
    survivors_tally = SURVIVOR.names.map do |name|
      display = fix(name)
      display = "#{number+=1}:#{display}"
      if name == @pardoned
        # If the player was pardoned, display their name in exclamations.
        @pardoned = nil
        display = "!#{display}!"
      end
      [ display,
        SURVIVOR.ff(name), SURVIVOR.exposure(name), SURVIVOR.pardons(name) ]
      .join('-')
    end
    .join('  ')
    @rankings = Time.now
    survivors_tally
  end

  # The kickid command is used to kick players by their id.
  def kickid(id, msg)
    %(kickid #{id} "#{msg}")
  end

  # This is a robust kick command that can kick by name or id.
  def kick!(name, msg)
    (id = SURVIVOR.id(name))? kickid(id, msg) : %(kick "#{name}")
  end

  # Kick player unless they have a pardon.
  def kick(name, msg)
    if SURVIVOR.pardons(name).positive?
      SURVIVOR.decrement_pardons(name)
      @pardoned = name
      nil
    else
      kick!(name, msg)
    end
  end

  # Determine if either the attacker or victim is to be kicked.
  def kick?(attacker, victim)
    if SURVIVOR.kicks(attacker) > EXCESSIVE_KICKS
      # If the attacker has been kicked excessively,
      # kick the atacker and forgive the victim.
      SURVIVOR.decrement_exposure(victim)
      kick! attacker, 'kicked AGAIN!'
    elsif SURVIVOR.kicks(victim) > EXCESSIVE_KICKS
      # If the victim has been kicked excessively,
      # kick the victim and forgive the attacker.
      SURVIVOR.decrement_ff(attacker)
      kick! victim, 'kicked AGAIN!'
    elsif SURVIVOR.ff(attacker) > EXCESSIVE_LIMIT
      # If the attacker has exceeded the FF limit,
      # kick the attacker and forgive all other players an exposure.
      SURVIVOR.decrement_exposure_for_all(except: attacker)
      kick attacker, 'kicked for FF(excessive)'
    elsif attacker == SURVIVOR.lvp
      # This is the most valuable guard against trolls.
      # Newcomers start out as lvp, and they'll be kicked immediately for FF.
      # If the attacker is the least valuable player,
      # kick the attacker and forgive the victim.
      SURVIVOR.decrement_exposure(victim)
      kick attacker, 'kicked for FF(demotion)'
    elsif SURVIVOR.exposure(victim) > EXPOSURE_LIMIT
      # As the last check, if the victim has exceeded the exposure limit,
      # kick the victim and forgive all other players an FF.
      SURVIVOR.decrement_ff_for_all(except: victim)
      kick victim, 'kicked for FF(exposure)'
    end
  end

  # The server dumps a lot of information to the terminal.
  # I try to filter out the noise and only display the important stuff.
  # The @trace and @verbose flags can be set via the terminal by entering
  # respectively: trace and verbose.
  def info(line)
    case line
    when /^Network: IP [\d.]+,/, /^   VAC /, /^Console: /
      PUTS.terminal line, :yellow
    when /^Can't kick "/, /^Unknown command "/
      PUTS.terminal line, :magenta
    when / was never closed$/,
      /^Couldn't find any entities named /,
      /^Invalid counterterrorist spawnpoint at /,
      /^String Table dictionary for /,
      /^Saving weapon_/,
      /^Removing weapon_/,
      /^Recreating weapon_/,
      /^Late precache of /,
      /^SURVIVORBOT /,
      /^RecordSteamInterfaceCreation /,
      /^ConVarRef /
      PUTS.terminal line if @verbose
    else
      PUTS.terminal line if @trace
    end
  end

  def potential_vote
    lvp = SURVIVOR.lvp
    if SURVIVOR.playtime(lvp) < VOTE_INTERVAL
      # Pissed off by the vote call, the Observer kicks the LVP if
      # the LVP has not played long enough.
      # But seriously, this prevents server hijacking.
      PUTS.console kick!(lvp, 'kicked for potential vote')
    end
  end

  def z_difficulty(difficulty)
    return if difficulty == 'Impossible' || SURVIVOR.lvp.nil?

    # The difficulty has been changed to something other than impossible.
    # This pisses off the Observer and so kicks the LVP.
    PUTS.console kick! SURVIVOR.lvp, 'kicked for not playing expert'
  end

  def level_restart
    SURVIVOR.names.each do |name|
      next unless SURVIVOR.playtime(name) > VOTE_INTERVAL &&
                  SURVIVOR.pardons(name) < 1 &&
                  SURVIVOR.pity(name) < PITY_LIMIT

      # The players have been killed... pity them.
      # Give a pardon to the player without pardons and
      # that has not exceded their pity.
      SURVIVOR.set_pardons(name, 1)
      SURVIVOR.increment_pity(name)
    end
  end

  def change_level
    SURVIVOR.clear_level
    SURVIVOR.names.each do |name|
      next unless SURVIVOR.pardons(name) < PARDONS_LIMIT &&
                  SURVIVOR.playtime(name) > VOTE_INTERVAL

      # As a reward for playing a while, give a pardon.
      SURVIVOR.increment_pardons(name)
    end
  end

  def dropped(dropped, why)
    return unless SURVIVOR.delete dropped

    SURVIVOR.set_pardons(dropped, 0) # Pardons are for staying.
    if SURVIVOR.playtime(dropped) < VOTE_INTERVAL
      # Players who leave before the vote interval are tallied as a kick.
      # This may be in addition to a tallied kick.
      SURVIVOR.increment_kicks(dropped)
    end

    # Quit if all players are gone.
    if SURVIVOR.none?
      PUTS.console 'exit'
      return # Don't mind a kick on lone survivor(as for chat?).
    end

    case why
    when 'Kicked by Console : You have been voted off'
      # The Observer is very jealous of its job and doesn't like it when
      # players vote to kick. Only the Observer kicks players off!
      PUTS.console kick!(SURVIVOR.lvp, 'kicked for kick vote')
    when /"(kicked .*)"$/
      # A player has been kicked from the server by the Observer.
      SURVIVOR.increment_kicks(dropped)
      PUTS.console say "#{fix(dropped)} #{$1}"
    end

    if dropped==@admin
      max = 0.0
      SURVIVOR.names.each do |name|
        playtime = SURVIVOR.playtime(name)
        if max < playtime
          max =  playtime
          @admin = name
        end
      end
      PUTS.console say "New Game Admin #{fix(@admin)}"
    end

    PUTS.console say rankings
  end

  def attacked(attacker, victim)
    pvp = SURVIVOR.pvp?(attacker, victim)
    case pvp
    when String
      # A player changed their name. Sending the "users" command to get the
      # cheater's id and kick the cheater out.
      PUTS.console 'users'
    when TrueClass
      SURVIVOR.tallies(attacker, victim)
      if (cmd = kick?(attacker, victim))
        PUTS.console cmd
      else
        SURVIVOR.demote attacker
        PUTS.console say rankings
      end
    end
  end

  def user_info(id, survivor)
    registered = SURVIVOR.register!(survivor, id)
    case registered
    when String
      # There was a problem with the name.
      if SURVIVOR.delete(registered, id)
        PUTS.console kickid(id, 'kicked for name registration issue')
      end
    when TrueClass
      if SURVIVOR.kicks(survivor) > EXCESSIVE_KICKS
        PUTS.console say "#{fix(survivor)} is a troll!"
      else
        if @admin.nil? || survivor==ADMIN
          @admin = survivor
          PUTS.console say "New Game Admin #{fix(survivor)}"
        end
        SURVIVOR.balance_rankings(survivor)
        PUTS.console say rankings
      end
    end
  end

  def client_connected(survivor, ip)
    SURVIVOR.add survivor, ip
    PUTS.console 'users' # show user info for players on the server
  end

  # Here I process each line the server outputs.
  def process(line)
    case line
    when /Client "(.*)" connected \(([^:]*):.*\)\.$/
      # A new player has connected to the server.
      # Could not anchor start of line bc previous line error joins sometimes.
      PUTS.terminal line, :blue
      client_connected($1, $2) # survivor,ip = $1,$2
    when /^\d+:(\d+):"(.*)"$/
      # This line is the result of the "users" console command.
      # This is information about a player on the server.
      PUTS.terminal line, :green
      user_info($1, $2) # id,survivor = $1,$2
    when /^(.*) attacked (.*)$/
      # A player has attacked another player.
      PUTS.terminal line, :red
      attacked($1, $2) # attacker,victim = $1,$2
    when /^Dropped (.+) from server \((.+)\)$/
      # A player has disconnected from the server.
      PUTS.terminal line, :blue
      dropped($1, $2) # dropped,why = $1,$2
    when /^Can't kick "(.*)", name not found$/
      # Player changed their name and left?
      PUTS.terminal line, :red
      dropped($1, 'kicked for name change')
    when '---- Host_Changelevel ----'
      # Players made it to the safe room.
      PUTS.terminal line, :yellow
      change_level
    when "Initializing Director's script"
      # Players have all died
      PUTS.terminal line, :yellow
      level_restart
    when /^"z_difficulty" = "(\w+)"/
      PUTS.terminal line, :yellow
      z_difficulty($1)
    when /^Potential vote being called$/
      PUTS.terminal line, :red
      potential_vote
    when /\b#{@admin}: !idle([1234])$/
      # It's very hard to detect idle players from the server's log.
      # When the server admin plays, the admin gets to kick players...
      # meant to be used against idle players.
      # Note that one can configure the controller to send messages to the
      # console.
      PUTS.terminal line, :red
      if (name = SURVIVOR.names[$1.to_i - 1]) && name != @admin
        PUTS.console kick!(name, 'kicked for idle')
      end
    when /\b#{@admin}: !users$/
      PUTS.terminal line, :red
      PUTS.console 'users'
    else
      # The sever config allows one to disable voice chat.
      # But text chat is still available(can't be disabled).
      # The Observer finds this very annoying and
      # kicks players that use text chat.
      if (name = SURVIVOR.names.reverse.detect{line.include? "#{_1}:"})
        PUTS.terminal line, :red
        PUTS.console kick!(name, 'kicked for chat')
      else
        info(line)
      end
    end
  rescue
    PUTS.error 'In process'
  end

  LINES = Thread::Queue.new
  def handle_lines
    while (line = LINES.pop)
      LOGS.push line
      break if line == :exit
      process(line)
    end
  rescue
    PUTS.error 'In handle_lines'
  end

  # Notice that every line emitted by the server is appended to the log file.
  # This is important because it allows one to review the raw output of the
  # server. On the other hand, the output to the terminal is filtered.
  LOGS = Thread::Queue.new
  def handle_log
    while (line = LOGS.pop)
      break if line == :exit
      PUTS.log line
    end
  rescue
    PUTS.error 'In handle_log'
  end

  # The server is started with the -console option. This allows us to send
  # commands to the server via stdin. This is used to change the trace level.
  def handle_stdin
    while (cmd = $stdin.gets)
      cmd.strip!
      case cmd
      when 'trace'
        @trace = true; @verbose = false
      when 'verbose'
        @trace = @verbose = true
      when 'quiet'
        @trace = @verbose = false
      when 'quit'
        PUTS.terminal "Don't say quit, say exit please."
      else
        # If none of the above, then send the command to the server via console.
        @trace = true # will want to see the output
        PUTS.console cmd
      end
    end
  rescue
    PUTS.error 'In handle_stdin'
  end

  def handle_checks
    loop do
      sleep rand RANDOM_TIME
      now = Time.now
      if now - @difficulty > VOTE_INTERVAL
        # From time to time, check the difficulty.
        # Elsewhere, the difficulty is checked and if it is not expert,
        # the LVP is kicked.
        @difficulty = Time.now
        PUTS.console 'z_difficulty'
      elsif now - @rankings > RANDOM_TIME
        # If the rankings have not been displayed for a while, display them.
        PUTS.console say rankings unless SURVIVOR.none?
      end
    end
  end

  def initialize
    @admin = @pardoned = nil
    @difficulty = @rankings = Time.now
    @trace = @verbose = false
    PTY.spawn(CMD) do |reader, writer, _pid|
      PUTS.console = writer
      @checks_thread = Thread.new { handle_checks }
      @stdin_thread = Thread.new { handle_stdin }
      Thread.new { handle_log }
      Thread.new { handle_lines }
      reader.each do |line|
        LINES.push line.encode('UTF-8', invalid: :replace, replace: X).chomp
      end
    end
  rescue Errno::EIO
    # It's OK, go on...
  ensure
    @stdin_thread.kill
    @checks_thread.kill
    LINES.push :exit
    SURVIVOR.tally_dump
  end
end
end
