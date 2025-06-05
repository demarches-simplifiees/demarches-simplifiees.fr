# frozen_string_literal: true

class PasswordComplexityController < ApplicationController
  def show
    @length = password_param.to_s.length
    @score = ZxcvbnService.complexity(password_param)
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
