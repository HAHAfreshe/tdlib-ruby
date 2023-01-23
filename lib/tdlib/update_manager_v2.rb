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
    update = TD::ApiV2.client_receive(TIMEOUT)
    case update['@type'] 
    when 'updateUser', 'updateSupergroup', 'updateSupergroupFullInfo', 'updateNewChat', 'updateChatLastMessage', 'updateNewMessage', 'updateUserStatus', 'updateDeleteMessages', 'updateChatAction', 'updateMessageInteractionInfo', 'updateBasicGroup', 'updateMessageContent', 'updateMessageEdited'
      meta = {}
      meta[:type]   = :update
      meta[:profile]   = profile
      meta[:timestamp] = DateTime.now.strftime('%Q')
      bus.send(meta: meta, data: update.to_h)
      
    when 'updateConnectionState', 'updateOption', 'updateActiveEmojiReactions', 'updateUnreadChatCount', 'updateScopeNotificationSettings', 'updateAnimationSearchParameters', 'updateDefaultReactionType', 'updateAttachmentMenuBots', 'updateSelectedBackground', 'updateSelectedBackground', 'updateFileDownloads', 'updateDiceEmojis', 'updateChatThemes', 'updateChatFilters', 'updateUnreadMessageCount', 'updateChatReadInbox', 'updateHavePendingNotifications', 'updateSuggestedActions', 'updateChatReadOutbox', 'updateAuthorizationState', 'updateChatPosition'
    else
      # # p "#UNREG#"
      # p update
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
