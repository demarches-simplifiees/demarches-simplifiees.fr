# frozen_string_literal: true

class SwitchDomainBannerComponent < ApplicationComponent
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def render?
    return false unless helpers.switch_domain_enabled?(request)

    # TODO if preferred hosts

    true
  end

  def auto_switch?
    helpers.auto_switch_domain?(request, user.present?)
  end

  def manual_switch?
    helpers.app_host_legacy?(request) && user.present?
  end

  def new_host_url
    helpers.url_for(url_options)
  end

  end

  private

  def url_options
    request.params.except(:switch_domain).merge(host: ApplicationHelper::APP_HOST)
  end
end
