# frozen_string_literal: true

FactoryBot.define do
  factory :dossier_operation_log do
    operation { :passer_en_instruction }

    trait :with_serialized do
      serialized { Rack::Test::UploadedFile.new('spec/fixtures/files/white.png', 'image/png') }
    end
  end
end
