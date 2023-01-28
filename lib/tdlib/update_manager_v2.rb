class TD::UpdateManagerV2
  TIMEOUT = 20

  def initialize
    @handlers = Concurrent::Array.new
    @mutex = Mutex.new
  end

  def add_handler(handler)
    @mutex.synchronize { @handlers << handler }
  end

  alias << add_handler

  def run(profile, bus)
    #@thread_pool.post do
    #       puts 'post'
    Thread.start do
      loop { handle_update(profile, bus); sleep 0.00001 }
      @mutex.synchronize { @handlers = [] }
    end
  end

  private
  attr_reader :handlers

  def handle_update(profile, bus)
    
    updateNotifier = ['updatePoll', 'updateUser', 'updateUsersNearby', 'updateUserFullInfo' 'updateSupergroup', 'updateSupergroupFullInfo', 'updateNewChat', 'updateChatLastMessage', 'updateNewMessage', 'updateUserStatus', 'updateDeleteMessages', 'updateChatAction', 'updateMessageInteractionInfo', 'updateBasicGroup', 'updateMessageContent', 'updateMessageEdited', 'updateBasicGroupFullInfo', 'updateChatMember', 'updateChatMessageSender', 'updateChatMessageTtl', 'updateChatNotificationSettings', 'updateChatOnlineMemberCount', 'updateChatPendingJoinRequests', 'updateChatPermissions', 'updateChatPhoto', 'updateMessageSendAcknowledged', 'updateMessageSendSucceeded', 'updateNewCallbackQuery', 'updateNewChatJoinRequest', 'updateNewChosenInlineResult', 'updateNewCustomEvent', 'updateNewCustomQuery', 'updateNewInlineCallbackQuery', 'updateNewInlineQuery', 'updateNewPreCheckoutQuery', 'updateNewShippingQuery', 'updatePollAnswer', 'updateServiceNotification', 'updateCall', 'updateAnimatedEmojiMessageClicked']
    
    update = TD::ApiV2.client_receive(TIMEOUT)
    begin
      if update.class == Hash && updateNotifier.include?(update['@type'])
        data = update.to_h
        #
        meta = {}
        meta[:type]   = :update
        meta[:profile]   = profile
        meta[:timestamp] = DateTime.now.strftime('%Q').to_i
        meta[:tdType]    = data['@type']
        meta[:dataThumb] = Digest::SHA1.hexdigest(update.to_s)
        meta[:uuid]      = Digest::SHA1.hexdigest("#{meta[:timestamp]}::#{meta[:type]}::#{meta[:profile]}::#{meta[:tdType]}::#{meta[:dataThumb]}")          
        #
        bus.send(meta: meta, data: data)
      end
    rescue => e
      p "TDLIB SEND UPDATE ERROR: #{e}"
    end

    unless update.nil?
      extra  = update.delete('@extra')
      update = TD::Types.wrap(update)

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
