class TD::UpdateManager
  TIMEOUT = 30

  def initialize
    @handlers = Concurrent::Array.new
    @mutex = Mutex.new
    @updates_count = 0
  end

  def add_handler(handler)
    @mutex.synchronize { @handlers << handler }
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
      extra = update.delete("@extra")
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
    @mutex.synchronize do
      matched_handlers = handlers.select { |h| h.match?(update, extra) }
      matched_handlers.each { |h| handlers.delete(h) if h.disposable? }
      matched_handlers
    end
  end
end
