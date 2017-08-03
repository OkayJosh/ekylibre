# Small wrapper around the Rails.env variable that allows
# us to pretend we're in another env than the actual one.
class PseudoEnvironment < SimpleDelegator
  attr_reader :real_env, :current_env, :scope, :explicit_label

  def initialize(caller, explicit_label=true)
    @scope = caller
    @real_env = Rails.env
    @explicit_label = explicit_label
    super(@real_env)
  end

  def set_to(new_env)
    unset
    @current_env = new_env
    Rails.instance_variable_set(:@_env, self)

    define_env_response(@real_env, false)
    define_env_response(@current_env, true)
    return new_env unless block_given?

    yield

    unset
  end

  def unset
    return unless current_env.present?
    class << self
      env_test = :"#{Rails.env.current_env}?"
      undef_method env_test if defined?(env_test)
    end
    Rails.instance_variable_set(:@_env, real_env)
    real_env
  end

  def inspect
    main_env = @current_env || @real_env
    label = "#{main_env}"
    return label unless explicit_label
    "#{label} (actual: #{real_env})"
  end

  private

  def define_env_response(env, response)
    define_singleton_method(:"#{env}?") do
      in_caller = binding.callers.find { |binding| binding.eval('self') == scope }
      return response if in_caller
      real_env.send("#{env}?")
    end
  end
end
