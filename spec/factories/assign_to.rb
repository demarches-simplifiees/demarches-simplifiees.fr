# frozen_string_literal: true

FactoryBot.define do
  factory :assign_to do
    groupe_instructeur { procedure.defaut_groupe_instructeur }
  end
end
