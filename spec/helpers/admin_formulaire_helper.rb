require 'rails_helper'

RSpec.describe AdminFormulaireHelper, type: :helper do
  let(:procedure) { create(:procedure) }
  let(:kind) { 'piece_justificative' }
  let(:url) { 'http://localhost' }
  let!(:type_de_piece_justificative_0) { create(:type_de_piece_justificative, procedure: procedure, order_place: 0) }
  let!(:type_de_piece_justificative_1) { create(:type_de_piece_justificative, procedure: procedure, order_place: 1) }
  let!(:type_de_piece_justificative_2) { create(:type_de_piece_justificative, procedure: procedure, order_place: 2) }

  describe '#button_up' do
    describe 'with first piece justificative' do
      let(:index) { 0 }

      it 'returns a button up' do
        expect(button_up(procedure, kind, index, url)).to be(nil)
      end
    end

    describe 'with second out of three piece justificative' do
      let(:index) { 1 }

      it 'returns a button up' do
        expect(button_up(procedure, kind, index, url)).to match(/fa-chevron-up/)
      end
    end

    describe 'with last piece justificative' do
      let(:index) { 2 }

      it 'returns a button up' do
        expect(button_up(procedure, kind, index, url)).to match(/fa-chevron-up/)
      end
    end
  end

  describe '#button_down' do
    describe 'with first piece justificative' do
      let(:index) { 0 }

      it 'returns a button down' do
        expect(button_down(procedure, kind, index, url)).to match(/fa-chevron-down/)
      end
    end

    describe 'with second out of three piece justificative' do
      let(:index) { 1 }

      it 'returns a button down' do
        expect(button_down(procedure, kind, index, url)).to match(/fa-chevron-down/)
      end
    end

    describe 'with last piece justificative' do
      let(:index) { 2 }

      it 'returns nil' do
        expect(button_down(procedure, kind, index, url)).to be(nil)
      end
    end
  end
end
