# frozen_string_literal: true

FactoryBot.define do
  factory :dossier_submitted_message do
    message_on_submit_by_usager { "BAM !" }
  end
end
