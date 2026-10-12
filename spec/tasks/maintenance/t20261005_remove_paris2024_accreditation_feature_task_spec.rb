# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20261005RemoveParis2024AccreditationFeatureTask do
    let(:gates) { Flipper::Adapters::ActiveRecord::Gate }
    let(:procedure) { procedures.individual }

    before do
      @previous_flipper = Flipper.instance
      Flipper.instance = Flipper.new(Flipper::Adapters::ActiveRecord.new)
    end

    after { Flipper.instance = @previous_flipper }

    it 'never targets a flag the code still declares' do
      declared = Rails.root.join('config/initializers/flipper.rb').read
        .scan(/^\s*:(\w+),?\s*$/).flatten

      expect(described_class::OBSOLETE_FEATURES.map(&:to_s) & declared).to be_empty
    end

    it 'removes the flag and the procedures it was enabled for' do
      Flipper.enable_actor(:cojo_type_de_champ, procedure)

      expect { described_class.process(:cojo_type_de_champ) }
        .to change { gates.where(feature_key: 'cojo_type_de_champ').count }.to(0)
      expect(Flipper.features.map(&:key)).not_to include('cojo_type_de_champ')
    end
  end
end
