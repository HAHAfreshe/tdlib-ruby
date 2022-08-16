class TD::UpdateManager
  TIMEOUT = 30

  def initialize
    @handlers = {}
    @mutex = Mutex.new
    @updates_count = 0
  end

  def add_handler(handler)
    key = handler.extra || handler.update_type
    @handlers[key] ||= []
    @handlers[key] << handler
  end

  alias << add_handler

  def run(&interrupt_callback)
    Async do
      LOGGER.info "main loop started"
      @reported_at = Time.now
      loop do
        handle_update
        sleep 0.0001
        Signal.trap('INT') { interrupt_callback.call }
      end
      @mutex.synchronize { @handlers = [] }
    end
  end

  private

  attr_reader :handlers

  def handle_update
    sleep 0.0005 # This is needed to switch to another thread
    update = TD::Api.client_receive(TIMEOUT)

    unless update.nil?
      @updates_count += 1
      passed_time = Time.now - @reported_at
      if passed_time >= 15
        rate = @updates_count / passed_time
        if rate > 300
          LOGGER.info "Updates per second: #{rate}"
        else
          LOGGER.debug "Updates per second: #{rate}"
        end

        @reported_at = Time.now
        @updates_count = 0
      end
      extra = update.delete(:@extra)
      update = TD::Types.wrap(update)

      match_handlers!(update, extra).each do |h|
        Async do
          h.run(update)
        end
      end
    end
  rescue StandardError => e
    warn("Uncaught exception in update manager: #{e.message}")
  end

  def match_handlers!(update, extra)
    key = extra || update.class
    update_handlers = @handlers[key]
    return [] unless update_handlers

    persistent_handlers = update_handlers.reject(&:disposable)
    if persistent_handlers.empty?
      @handlers.delete(key)
    else
      @handlers[key] = persistent_handlers
    end
    update_handlers
  end
end
