# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250318FixIndividualGenderTask do
    describe '#collection' do
      subject(:collection) { described_class.collection }

      context 'valid gender' do
        let(:individual) { create(:individual) }

        it do
          expect(collection).not_to include(individual)
        end
      end

      context 'invalid gender' do
        let(:individual) { create(:individual, gender: "traduction") }

        it do
          expect(collection).to include(individual)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(individual) }

      context 'know invalid gender' do
        let(:individual) { create(:individual, gender: described_class::GENDER.keys.first) }

        it do
          subject
          expect(individual.reload.gender).to eq(described_class::GENDER.values.first)
        end
      end

      context 'unknow invalid gender' do
        let(:individual) { create(:individual, gender: "traduction") }

        it do
          subject
          expect(individual.reload.gender).to eq('Mme')
        end
      end
    end
  end
end
