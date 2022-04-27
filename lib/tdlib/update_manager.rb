class TD::UpdateManager
  TIMEOUT = 30

  def initialize
    @handlers = {}
    @mutex = Mutex.new
    @updates_count = 0
  end

  def add_handler(handler)
    if handler.extra
      key = handler.extra
    else
      key = handler.update_type
    end
    @handlers[key] ||= []
    @handlers[key] << handler
  end

  alias << add_handler

  def run
    Async do
      LOGGER.info "main loop started"
      @reported_at = Time.now
      loop do
        handle_update
        sleep 0.00001
      end
      @mutex.synchronize { @handlers = [] }
    end
  end

  private

  attr_reader :handlers

  def handle_update
    sleep 0.00001
    update = TD::Api.client_receive(TIMEOUT)

    unless update.nil?
      @updates_count += 1
      passed_time = Time.now - @reported_at
      if passed_time >= 1
        LOGGER.warn "handled #{@updates_count / passed_time} updates per s"
        @reported_at = Time.now
        @updates_count = 0
      end
      extra = update.delete(:@extra)
      update = TD::Types.wrap(update)

      # puts "new update #{update.class}"
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
    key = if extra
            extra
          else
            update.class
          end
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
