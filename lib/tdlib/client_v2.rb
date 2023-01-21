require "securerandom"

# Simple client for TDLib.
class TD::ClientV2
  include TD::ClientMethods

  TIMEOUT = 20

  def self.ready(*args)
    new(*args).connect
  end

  # @param [FFI::Pointer] td_client
  # @param [TD::UpdateManager] update_manager
  # @param [Numeric] timeout
  # @param [Hash] extra_config optional configuration hash that will be merged into tdlib client configuration
  def initialize(td_client_id = TD::ApiV2.create_client,
                 update_manager = TD::UpdateManagerV2.new,
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
    @close_condition = Async::Condition.new
  end

  # Adds initial authorization state handler and runs update manager
  # Returns future that will be fulfilled when client is ready

  def connect
    p "client :: connect :: start"                            
    on TD::Types::Update::AuthorizationState do |update|
      case update.authorization_state
      when TD::Types::AuthorizationState::WaitTdlibParameters
        set_tdlib_parameters(**@config)
      when TD::Types::AuthorizationState::Closed
        p "client :: connect :: Received TD::Types::AuthorizationState::Closed"
        @alive = false
        @ready = false
        @close_condition.signal
        Async::Task.current.reactor.stop
      else
        # do nothing
      end
    end
    Async do
      Async do
        p "client :: connect :: get_authorization_state :: pre"
        get_authorization_state
        p "client :: connect :: get_authorization_state :: post"           
      end
      #Async do
        @update_manager.run do
          Async do
            p "client :: dispose :: pre"    
            dispose.wait #!!!!!!!
            p "client :: dispose :: post"    
            exit
          end
        end
      #end
      Async do
        p "client :: connect :: ready :: pre"                    
        ready
        p "client :: connect :: ready :: post"                    
      end
      begin
        Async::Task.current.reactor.stop
      rescue
        p 'rescue'
      end
    end
    p "client :: connect :: end"   
    
  end

  # @example
  #   client.broadcast(some_query).then { |result| puts result }.rescue { |error| puts [error.code, error.message] }
  # @param [Hash] query
  # @return
  def broadcast(query)
    return dead_client_error if dead?

    Async do
      condition = Async::Condition.new
      extra = SecureRandom.uuid

      #Async do
        p "client :: broadcast :: @update_manager :: pre :: #{query}"        
        @update_manager << TD::UpdateHandlerV2.new(extra:, disposable: true) do |update|
          condition.signal(update)
        end
        p "client :: broadcast :: @update_manager :: post"
      #end

      query["@extra"] = extra
      # TODO: simplify - raise error in recieve?
      Async do |task|
        p "client :: broadcast :: send_to_td_client :: pre = #{query}"        
        task.async do
          a = send_to_td_client(query)
          p "client :: broadcast :: send_to_td_client :: post = #{a}"          
        end
        
      end
      result = condition.wait
      error = nil
      error = result if result.is_a?(TD::Types::Error)
      error = timeout_error if result.nil?
      if error
        raise TD::Error, error if error.code != 429

        duration = error.message.match(%r{Too Many Requests: retry after (\d+)})[1].to_i
        p "client :: Being rate limited... #{query} waiting #{duration} seconds"
        Async do
          p "client :: broadcast :: error :: pre"          
          sleep duration
          broadcast(query)
          p "client :: broadcast :: error :: post"                    
        end.wait
      else
        result
      end
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

    TD::ApiV2.client_execute(query)
  end

  # Binds passed block as a handler for updates with type of *update_type*
  # @param [String, Class] update_type
  # @yield [update] yields update to the block as soon as it's received
  def on(update_type, &)
    if update_type.is_a?(String)
      if (type_const = TD::Types::LOOKUP_TABLE[update_type.to_sym])
        update_type = TD::Types.const_get("TD::Types::#{type_const}")
      else
        raise ArgumentError, "Can't find class for #{update_type}"
      end
    end

    @update_manager << TD::UpdateHandlerV2.new(update_type:, &)
  end

  # returns task that will be fulfilled when client is ready
  def ready
    Async do |task|
      p "client :: ready :: task :: pre"
      return dead_client_error if dead?
      return self if ready?

      task.with_timeout(@timeout) do
        Async do
          p "client :: ready :: taskRun :: pre"          
          next self if @ready          
          @ready_condition.wait

          next self if @ready

          raise dead_client_error
          p "client :: ready :: taskRun :: pre"                    
        end
      rescue Async::TimeoutError
        raise TD::Error, timeout_error
      end
      p "client :: ready :: task :: post"      
    end
  end

  # Stops update manager and destroys TDLib client
  def dispose
    return if dead?

    Async do
      close
      @close_condition.wait
    end
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

    TD::ApiV2.client_send(@td_client_id, query)
  end

  def timeout_error
    TD::Types::Error.new(code: 0, message: "Timeout error")
  end

  def dead_client_error
    TD::Error.new(TD::Types::Error.new(code: 0, message: "TD client is dead"))
  end
end
