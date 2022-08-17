class TD::UpdateManagerV2
  TIMEOUT = 30

  def initialize
    @handlers = {}
    @mutex = Mutex.new
    @updates_count = 0
  end

  def add_handler(handler)
    key = handler.extra || handler.update_type
    p "key : #{key}"
    p "handler : #{handler}"
    p 11
    p "@handlers : #{@handlers}" 
    p "@handlers[key] : #{@handlers[key]}"    
    @handlers[key]
    @handlers[key] ||= []
    p 22
    @handlers[key] << handler
  end

  alias << add_handler

  def run(&interrupt_callback)
    #task = Async do
      p "updateManager :: run :: loop :: pre"
      @reported_at = Time.now
      i = 0
      loop do
        i += 1
        #p 'updateManager :: update loop 1'        
        handle_update
        #p 'updateManager :: update loop 2'
        sleep 0.0001
        Signal.trap('INT') { interrupt_callback.call }
        p i 
        break if i > 90
      end
      p "updateManager :: run :: loop :: post"
      @mutex.synchronize { @handlers = {} }
    #end
    p "updateManager :: run :: end"    
  end

  private

  attr_reader :handlers

  def handle_update
    sleep 0.0005 # This is needed to switch to another thread
    update = TD::Api.client_receive(TIMEOUT)
    #p "updateManager :: update :: #{update}"

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
      extra = update.delete(:@extra)
      update = TD::Types.wrap(update)

      match_handlers!(update, extra).each do |h|
        Async do |task|
          p 'updateManager :: handle_update :: match_handlers :: pre'
          p "updateManager :: h :: #{h}"
          h.run(update)
          #task.stop
          p 'updateManager :: handle_update :: match_handlers :: post'          
        end
      end
      
      p "updateManager :: handle_update :: end"          
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
