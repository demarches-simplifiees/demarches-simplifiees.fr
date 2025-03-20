# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe FixDecimalNumberWithSpacesTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }
      let(:champ) { create(:champ_decimal_number, value:) }
      let(:element) { champ }

      context 'with nil' do
        let(:value) { 0 }
        it { expect { process }.not_to change { champ.reload.valid_value } }
      end
      context 'with simple number' do
        let(:value) { "120" }
        it { expect { process }.not_to change { champ.reload.valid_value } }
      end
      context 'with number having leading spaces' do
        let(:value) { " 120" }
        it { expect { process }.to change { champ.reload.valid_value }.from(nil).to("120") }
      end
      context 'with number having trailing spaces' do
        let(:value) { "120 " }
        it { expect { process }.to change { champ.reload.valid_value }.from(nil).to("120") }
      end
      context 'with number having leading and trailing spaces' do
        let(:value) { " 120 " }
        it { expect { process }.to change { champ.reload.valid_value }.from(nil).to("120") }
      end
      context 'with number having in between spaces' do
        let(:value) { "1 2 0" }
        it { expect { process }.to change { champ.reload.valid_value }.from(nil).to("120") }
      end
      context 'with number having in between tab' do
        let(:value) { "\t120\t" }
        it { expect { process }.to change { champ.reload.valid_value }.from(nil).to("120") }
      end
    end
  end
end
