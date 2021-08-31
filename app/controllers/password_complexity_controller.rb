class PasswordComplexityController < ApplicationController
  def show
    @score, @words, @length = ZxcvbnService.new(password_param).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
  end

  private

  def password_param
    params
      .transform_keys! { |k| params[k].try(:has_key?, :password) ? 'resource' : k }
      .dig(:resource, :password)
  end
end
