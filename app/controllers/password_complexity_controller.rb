# frozen_string_literal: true

class PasswordComplexityController < ApplicationController
  def show
    @score, @words, @length = ZxcvbnService.new(password_param).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = params[:complexity]&.to_i || PASSWORD_COMPLEXITY_FOR_ADMIN
  end

  private

  def password_param
    params
      .transform_keys! { |k| params[k].try(:has_key?, :password) ? 'resource' : k }
      .dig(:resource, :password)
  end
end
