class TD::UpdateHandlerV2
  attr_reader :update_type, :extra, :disposable

  def initialize(update_type: nil, extra: nil, disposable: nil, &action)
    if update_type.nil? && extra.nil?
      raise ArgumentError, "Provide either 'update_type' or 'extra' parameter"
    elsif !update_type.nil? && !extra.nil?
      raise ArgumentError, "You can't specify both 'update_type' and 'extra' parameters"
    elsif update_type && !(update_type < TD::Types::Base)
      raise ArgumentError, "Wrong type specified (#{update_type}). Should be of kind TD::Types::Base"
    end

    @action = action
    @update_type = update_type
    @extra = extra
    @disposable = disposable
  end

  def run(update)
    action.call(update)
  rescue StandardError => e
    warn("Uncaught exception in handler #{self}: #{e.message}")
    raise
  end

  def disposable?
    disposable
  end

  def to_s
    "TD::UpdateHandler (#{update_type}#{": #{extra}" if extra})#{' disposable' if disposable?}"
  end

  alias inspect to_s

  private

  attr_reader :action
end
