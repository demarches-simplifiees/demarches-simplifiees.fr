# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CleanCarteOptionsTask do
    describe '#collection' do
      subject(:collection) { described_class.collection }

      context 'clean carte tdc with all layers' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: {
                    "unesco" => "0",
                    "arretes_protection" => "0",
                    "conservatoire_littoral" => "0",
                    "reserves_chasse_faune_sauvage" => "0",
                    "reserves_biologiques" => "0",
                    "reserves_naturelles" => "0",
                    "natura_2000" => "0",
                    "zones_humides" => "0",
                    "znieff" => "0",
                    "cadastres" => "0"
                  })
        }

        it do
          expect(collection).not_to include(tdc)
        end
      end

      context 'clean carte tdc with no layer' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: {})
        }

        it do
          expect(collection).not_to include(tdc)
        end
      end

      context 'carte tdc with bad data options' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: {
                    "unesco" => "0",
                    "arretes_protection" => "0",
                    "conservatoire_littoral" => "0",
                    "reserves_chasse_faune_sauvage" => "0",
                    "reserves_biologiques" => "0",
                    "reserves_naturelles" => "0",
                    "natura_2000" => "0",
                    "zones_humides" => "0",
                    "znieff" => "0",
                    "cadastres" => "0",
                    'key' => 'value'
                  })
        }

        it do
          expect(collection).to include(tdc)
        end
      end

      context 'other tdc' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {
                    'header_section_level' => '1'
                  })
        }

        it do
          expect(collection).not_to include(tdc)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(tdc) }

      context 'at least one layer in clean tdc options' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: { 'cadastres' => '1' })
        }

        it do
          subject
          expect(tdc.reload.options).to eq({ 'cadastres' => '1' })
        end
      end

      context 'at least one layer in tdc options with bad data' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: {
                    'cadastres' => '1',
                    'key' => 'value'
                  })
        }

        it do
          subject
          expect(tdc.reload.options).to eq({ 'cadastres' => '1' })
        end
      end

      context 'bad data in options' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: {
                    "unesco" => "0",
                    "arretes_protection" => "0",
                    "conservatoire_littoral" => "0",
                    "reserves_chasse_faune_sauvage" => "0",
                    "reserves_biologiques" => "0",
                    "reserves_naturelles" => "0",
                    "natura_2000" => "0",
                    "zones_humides" => "0",
                    "znieff" => "0",
                    "cadastres" => "0",
                    'key' => 'value'
                  })
        }

        it do
          subject
          expect(tdc.reload.options).to eq({
            "unesco" => "0",
            "arretes_protection" => "0",
            "conservatoire_littoral" => "0",
            "reserves_chasse_faune_sauvage" => "0",
            "reserves_biologiques" => "0",
            "reserves_naturelles" => "0",
            "natura_2000" => "0",
            "zones_humides" => "0",
            "znieff" => "0",
            "cadastres" => "0"
          })
        end
      end

      context 'only bad data in options' do
        let(:tdc) {
          create(:type_de_champ_carte,
                  options: {
                    'key' => 'value'
                  })
        }

        it do
          subject
          expect(tdc.reload.options).to eq({})
        end
      end
    end
  end
end
