# frozen_string_literal: true

module MailerDolistConcern
  extend ActiveSupport::Concern

  included do
    before_action :add_dolist_header

    # mandatory for dolist
    # used for tracking in Dolist UI
    # the delivery_method is yet unknown (:balancer)
    # so we add the dolist header for everyone
    def add_dolist_header
      headers['X-Dolist-Message-Name'] = action_name
    end
  end
end
