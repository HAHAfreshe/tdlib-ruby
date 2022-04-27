require "securerandom"

# Simple client for TDLib.
class TD::Client
  include TD::ClientMethods

  TIMEOUT = 20

  def self.ready(*args)
    new(*args).connect
  end

  # @param [FFI::Pointer] td_client
  # @param [TD::UpdateManager] update_manager
  # @param [Numeric] timeout
  # @param [Hash] extra_config optional configuration hash that will be merged into tdlib client configuration
  def initialize(td_client_id = TD::Api.create_client,
                 update_manager = TD::UpdateManager.new,
                 timeout: TIMEOUT,
                 **extra_config)
    @td_client_id = td_client_id
    @ready = false
    @alive = true
    @update_manager = update_manager
    @timeout = timeout
    @config = TD.config.client.to_h.merge(extra_config)
    @ready_condition_mutex = Mutex.new
    @ready_condition = Async::Condition.new
  end

  # Adds initial authorization state handler and runs update manager
  # Returns future that will be fulfilled when client is ready

  def connect
    on TD::Types::Update::AuthorizationState do |update|
      case update.authorization_state
      when TD::Types::AuthorizationState::WaitTdlibParameters
        set_tdlib_parameters(parameters: TD::Types::TdlibParameters.new(**@config))
      when TD::Types::AuthorizationState::WaitEncryptionKey
        Async do
          LOGGER.info "check_database_encryption_key"
          check_database_encryption_key(encryption_key: TD.config.encryption_key).wait

          @ready = true
          @ready_condition.signal
        end
      when TD::Types::AuthorizationState::Closed
        LOGGER.warn "was closed"
        @alive = false
        @ready = false
        return
      else
        # do nothing
      end
    end
    Async do
      Async do
        LOGGER.debug "get_authorization_state"
        get_authorization_state
      end
      Async do
        LOGGER.debug "run"
        @update_manager.run
      end
      Async do
        ready
      end
    end
  end

  # @example
  #   client.broadcast(some_query).then { |result| puts result }.rescue { |error| puts [error.code, error.message] }
  # @param [Hash] query
  # @return
  def broadcast(query)
    LOGGER.debug "broadcast"
    return dead_client_error if dead?

    Async do
      condition = Async::Condition.new
      extra = SecureRandom.uuid

      Async do
        @update_manager << TD::UpdateHandler.new(extra:, disposable: true) do |update|
          condition.signal(update)
        end
      end

      query["@extra"] = extra
      # TODO: simplify - raise error in recieve?
      Async do |task|
        task.async do
          send_to_td_client(query)
          LOGGER.debug "after send_to_td_client"
        end
      end
      result = condition.wait
      error = nil
      error = result if result.is_a?(TD::Types::Error)
      error = timeout_error if result.nil?
      raise TD::Error, error if error

      result
    end
  end

  # Sends asynchronous request to the TDLib client and returns received update synchronously
  # @param [Hash] query
  # @return [Hash]
  def fetch(query)
    broadcast(query).wait
  end

  alias broadcast_and_receive fetch

  # Synchronously executes TDLib request
  # Only a few requests can be executed synchronously
  # @param [Hash] query
  def execute(query)
    return dead_client_error if dead?

    TD::Api.client_execute(query)
  end

  # Binds passed block as a handler for updates with type of *update_type*
  # @param [String, Class] update_type
  # @yield [update] yields update to the block as soon as it's received
  def on(update_type, &)
    if update_type.is_a?(String)
      if (type_const = TD::Types::LOOKUP_TABLE[update_type])
        update_type = TD::Types.const_get("TD::Types::#{type_const}")
      else
        raise ArgumentError, "Can't find class for #{update_type}"
      end
    end

    @update_manager << TD::UpdateHandler.new(update_type:, &)
  end

  # returns task that will be fulfilled when client is ready
  def ready
    Async do |task|
      return dead_client_error if dead?
      return self if ready?

      task.with_timeout(@timeout) do
        Async do
          next self if @ready

          @ready_condition.wait

          next self if @ready

          raise dead_client_error
        end
      rescue Async::TimeoutError
        raise TD::Error, timeout_error
      end
    end
  end

  # Stops update manager and destroys TDLib client
  def dispose
    return if dead?

    Async do
      puts "trying to close"
      close
      puts "after trying to close"
      Process.kill(9, Process.pid)
    end

    get_authorization_state
  end

  def alive?
    @alive
  end

  def dead?
    !alive?
  end

  def ready?
    @ready
  end

  private

  def send_to_td_client(query)
    return unless alive?

    TD::Api.client_send(@td_client_id, query)
  end

  def timeout_error
    TD::Types::Error.new(code: 0, message: "Timeout error")
  end

  def dead_client_error
    TD::Error.new(TD::Types::Error.new(code: 0, message: "TD client is dead"))
  end
end
