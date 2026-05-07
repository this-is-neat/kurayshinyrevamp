#===============================================================================
# Platinum Currency - Client API
# Server-authoritative currency system
# Client can only query balance and request spending
#===============================================================================

module MultiplayerPlatinum
  CASHOUT_RATE = 10

  def self.connected?
    if defined?(MultiplayerClient)
      connected = (MultiplayerClient.instance_variable_get(:@connected) rescue false)
      sid = (MultiplayerClient.session_id rescue nil).to_s.strip
      return true if connected || !sid.empty?
    end
    return $multiplayer.connected? if $multiplayer&.respond_to?(:connected?)
    false
  rescue
    false
  end

  def self.send_platinum_message(message)
    if defined?(MultiplayerClient)
      connected = (MultiplayerClient.instance_variable_get(:@connected) rescue false)
      if connected
        return MultiplayerClient.send_data(message, rate_limit_type: :GENERAL) if MultiplayerClient.respond_to?(:send_data)
        return MultiplayerClient.send_message(message) if MultiplayerClient.respond_to?(:send_message)
      end
    end
    return $multiplayer.send_message(message) if $multiplayer&.respond_to?(:send_message)
    false
  rescue
    false
  end

  def self.request_balance_update
    return false unless connected?

    if defined?(MultiplayerClient)
      connected = (MultiplayerClient.instance_variable_get(:@connected) rescue false)
      if connected && MultiplayerClient.respond_to?(:send_data)
        return MultiplayerClient.send_data("PLATINUM_BALANCE_REQ", rate_limit_type: :GENERAL)
      end
    end

    send_platinum_message("REQ_PLATINUM")
  rescue
    false
  end

  # Request current platinum balance from server
  # @return [Integer, nil] Current balance, or nil if not connected/timeout
  def self.get_balance
    return nil unless connected?

    ##MultiplayerDebug.info("PLATINUM", "Requesting balance from server")
    return nil unless request_balance_update

    # Wait for response with timeout
    previous_balance = (defined?($PokemonGlobal) && $PokemonGlobal) ? $PokemonGlobal.platinum_balance : nil
    start_time = Time.now
    timeout = 2.0

    while Time.now - start_time < timeout
      Graphics.update
      Input.update

      # Check if balance was updated
      if defined?($PokemonGlobal) && $PokemonGlobal && !$PokemonGlobal.platinum_balance.nil?
        balance = $PokemonGlobal.platinum_balance
        if previous_balance.nil? || balance != previous_balance || (Time.now - start_time) >= 0.15
          ##MultiplayerDebug.info("PLATINUM", "Balance received: #{balance} Pt")
          return balance
        end
      end
    end

    if defined?($PokemonGlobal) && $PokemonGlobal && !$PokemonGlobal.platinum_balance.nil?
      balance = $PokemonGlobal.platinum_balance
      ##MultiplayerDebug.info("PLATINUM", "Balance received: #{balance} Pt")
      return balance
    end

    ##MultiplayerDebug.warn("PLATINUM", "Balance request timeout")
    return nil
  end

  # Request to spend platinum on server
  # Server validates balance and triggers autosave on success
  # @param amount [Integer] Amount to spend (must be positive)
  # @param reason [String] Reason for spending (for server logging)
  # @return [Boolean] true if transaction succeeded, false otherwise
  def self.spend(amount, reason = "purchase")
    return false unless connected?

    if amount <= 0
      ##MultiplayerDebug.warn("PLATINUM", "Invalid amount: #{amount}")
      return false
    end

    ##MultiplayerDebug.info("PLATINUM", "Requesting spend: #{amount} Pt (#{reason})")

    # Clear previous transaction result
    $PokemonGlobal.last_platinum_transaction = nil

    # Send spend request
    return false unless send_platinum_message("SPEND_PLATINUM:#{amount},#{reason}")

    # Wait for response with timeout
    start_time = Time.now
    timeout = 3.0  # Longer timeout for transactions

    while Time.now - start_time < timeout
      Graphics.update
      Input.update

      # Check transaction result
      if $PokemonGlobal.last_platinum_transaction
        result = $PokemonGlobal.last_platinum_transaction
        $PokemonGlobal.last_platinum_transaction = nil

        case result
        when :SUCCESS
          ##MultiplayerDebug.info("PLATINUM", "Transaction succeeded")
          request_balance_update
          return true
        when :INSUFFICIENT
          ##MultiplayerDebug.warn("PLATINUM", "Insufficient balance")
          return false
        when :ERROR
          ##MultiplayerDebug.warn("PLATINUM", "Transaction error")
          return false
        else
          ##MultiplayerDebug.warn("PLATINUM", "Unknown result: #{result}")
          return false
        end
      end
    end

    ##MultiplayerDebug.warn("PLATINUM", "Transaction timeout")
    return false
  end

  # Get cached balance without querying server
  # @return [Integer] Cached balance, or 0 if not available
  def self.cached_balance
    return 0 unless defined?($PokemonGlobal) && $PokemonGlobal
    return $PokemonGlobal.platinum_balance || 0
  end

  # Check if player has enough platinum (uses cached balance)
  # @param amount [Integer] Amount to check
  # @return [Boolean] true if cached balance >= amount
  def self.can_afford?(amount)
    return cached_balance >= amount
  end

  def self.cashout_value(platinum_amount)
    platinum_amount.to_i * CASHOUT_RATE
  end

  def self.cashout_max_amount(refresh: false)
    balance = cached_balance.to_i
    if connected? && (refresh || balance <= 0)
      fresh_balance = get_balance rescue nil
      balance = fresh_balance.to_i unless fresh_balance.nil?
    end
    balance < 0 ? 0 : balance
  rescue
    0
  end

  def self.prompt_cashout_amount(max_amount = nil, initial_amount = 1, &block)
    max_amount = max_amount.to_i
    max_amount = cashout_max_amount(refresh: true) if max_amount <= 0
    return nil if max_amount <= 0

    params = ChooseNumberParams.new
    params.setRange(1, max_amount)
    params.setInitialValue([[initial_amount.to_i, 1].max, max_amount].min)
    params.setCancelValue(0)
    choice = pbMessageChooseNumber(
      _INTL("How many Platinum do you want to cash out? 1 Pt = ${1}.", CASHOUT_RATE),
      params, &block
    )
    choice = choice.to_i
    choice > 0 ? choice : nil
  rescue
    nil
  end

  def self.convert_to_money(platinum_amount = 1, money_amount = nil, reason = "money_convert")
    return [false, "Platinum conversion unavailable."] unless defined?($Trainer) && $Trainer
    return [false, "Platinum conversion requires multiplayer connection."] unless connected?

    platinum_amount = platinum_amount.to_i
    money_amount = cashout_value(platinum_amount) if money_amount.nil?

    balance = cached_balance.to_i
    if balance < platinum_amount
      fresh_balance = get_balance rescue nil
      return [false, "Couldn't verify your Platinum balance."] if fresh_balance.nil?
      balance = fresh_balance.to_i
    end

    return [false, "You need at least #{platinum_amount} Platinum."] if balance < platinum_amount
    return [false, "Platinum conversion failed."] unless spend(platinum_amount, reason)

    $Trainer.money += money_amount.to_i
    [true, money_amount.to_i]
  rescue
    [false, "Platinum conversion failed."]
  end

  # Internal: Update cached balance (called by client message handler)
  # @param amount [Integer] New balance from server
  def self.set_balance(amount)
    return unless defined?($PokemonGlobal) && $PokemonGlobal
    $PokemonGlobal.platinum_balance = amount
    ##MultiplayerDebug.info("PLATINUM", "Balance updated: #{amount} Pt")
  end

  # Internal: Set transaction result (called by client message handler)
  # @param result [Symbol] :SUCCESS, :INSUFFICIENT, :ERROR
  def self.set_transaction_result(result)
    return unless defined?($PokemonGlobal) && $PokemonGlobal
    $PokemonGlobal.last_platinum_transaction = result
    ##MultiplayerDebug.info("PLATINUM", "Transaction result: #{result}")
  end

  # Internal: Store auth token for current server (called by client on AUTH_TOKEN)
  # @param token [String] Authentication token from server
  def self.store_token(server_key, token)
    return unless defined?($PokemonGlobal) && $PokemonGlobal
    $PokemonGlobal.platinum_tokens ||= {}
    $PokemonGlobal.platinum_tokens[server_key] = token
    ##MultiplayerDebug.info("PLATINUM", "Token stored for server: #{server_key}")
  end

  # Internal: Get auth token for current server
  # @param server_key [String] "host:port" identifier
  # @return [String, nil] Token if exists, nil otherwise
  def self.get_token(server_key)
    return nil unless defined?($PokemonGlobal) && $PokemonGlobal
    $PokemonGlobal.platinum_tokens ||= {}
    return $PokemonGlobal.platinum_tokens[server_key]
  end
end
