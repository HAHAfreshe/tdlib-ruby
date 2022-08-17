class TD::UpdateManager
  TIMEOUT = 30

  def initialize(td_client)
    @td_client = td_client
    @handlers = Concurrent::Array.new
    @mutex = Mutex.new
    @updates_count = 0    
  end

  def add_handler(handler)
    @mutex.synchronize { @handlers << handler }
  end

  alias << add_handler

  def run(callback: nil)
    Thread.start do
      @reported_at = Time.now      
      catch(:client_closed) { loop { handle_update(callback: callback); sleep 0.001 } }
      @mutex.synchronize { @handlers = [] }
    end
  end

  private

  attr_reader :handlers

  def handle_update(callback: nil)
    update = TD::Api.client_receive(@td_client, TIMEOUT)

    unless update.nil?
      @updates_count += 1
      passed_time = Time.now - @reported_at
      if passed_time >= 15
        rate = @updates_count / passed_time
        if rate > 300
          p "updateManager :: Updates per second: #{rate}"
        else
          p "updateManager :: Updates per second: #{rate}"
        end

        @reported_at = Time.now
        @updates_count = 0
      end
      extra  = update.delete('@extra')
      update = TD::Types.wrap(update)
      callback&.call(update)

      match_handlers!(update, extra).each { |h| h.async.run(update) }
    end    
    
  rescue StandardError => e
    warn("Uncaught exception in update manager: #{e.message}")
  end

  def match_handlers!(update, extra)
    @mutex.synchronize do
      matched_handlers = handlers.select { |h| h.match?(update, extra) }
      matched_handlers.each { |h| handlers.delete(h) if h.disposable? }
      matched_handlers
    end
  end
end
