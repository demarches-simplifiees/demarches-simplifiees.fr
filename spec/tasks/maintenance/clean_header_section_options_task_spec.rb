# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CleanHeaderSectionOptionsTask do
    describe "#process" do
      subject(:process) { described_class.process(tdc) }

      context 'bad data in options' do
        let(:tdc) {
          create(:type_de_champ_header_section,
                  options: {
                    'header_section_level' => '1',
                    'key' => 'value'
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
