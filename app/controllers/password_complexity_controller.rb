# frozen_string_literal: true

class PasswordComplexityController < ApplicationController
  def show
    password = password_param
    @length = password.to_s.length
    @score = ZxcvbnService.complexity(password)
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
