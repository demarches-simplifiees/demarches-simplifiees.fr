# frozen_string_literal: true

module Manager
  class EmailEventsController < Manager::ApplicationController
    def index
      @dolist_enabled = Dolist::API.new.properly_configured?

      super
    end

    def generate_dolist_report
      email = current_super_admin.email

      DolistReportJob.perform_later(email)

      respond_to do |format|
        @message = "Le rapport sera envoyé sur #{email}. Il peut prendre plus d'1h pour être généré."

        format.turbo_stream

        format.html do
          redirect_to manager_email_events_path, notice: @message
        end
      end
    end
  end
end
