# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CleanHeaderSectionOptionsTask do
    describe '#collection' do
      subject(:collection) { described_class.collection }

      context 'clean header_section tdc with header_section_level' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {
                    'header_section_level' => '1',
                  })
        }

        it do
          expect(collection).not_to include(tdc)
        end
      end

      context 'clean header_section tdc with no header_section_level' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {})
        }

        it do
          expect(collection).not_to include(tdc)
        end
      end

      context 'header_section tdc with bad data options' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {
                    'header_section_level' => '1',
                    'key' => 'value',
                  })
        }

        it do
          expect(collection).to include(tdc)
        end
      end

      context 'other tdc' do
        let(:tdc) {
          create(:type_de_champ_textarea,
                  options: {
                    'character_limit' => '400',
                  })
        }

        it do
          expect(collection).not_to include(tdc)
        end
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(tdc) }

      context 'bad data in options' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {
                    'header_section_level' => '1',
                    'key' => 'value',
                  })
        }

        it do
          subject
          expect(tdc.reload.options).to eq({ 'header_section_level' => '1' })
        end
      end

      context 'only bad data in options' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {
                    'key' => 'value',
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
