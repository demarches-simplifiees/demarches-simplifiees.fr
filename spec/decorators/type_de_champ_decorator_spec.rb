
require 'spec_helper'

describe TypeDeChampDecorator do
  let(:procedure) { create(:procedure) }
  let(:url) { 'http://localhost' }
  let(:params) { { url: url, index: index } }
  let!(:type_de_champ_0) { create(:type_de_champ_public, procedure: procedure, order_place: 0) }
  let!(:type_de_champ_1) { create(:type_de_champ_public, procedure: procedure, order_place: 1) }
  let!(:type_de_champ_2) { create(:type_de_champ_public, procedure: procedure, order_place: 2) }

  describe '#button_up' do

    describe 'with first piece justificative' do
      let(:index) { 0 }
      subject { type_de_champ_0.decorate }
      let(:button_up) { type_de_champ_.decorate }

      it 'returns a button up' do
        expect(subject.button_up(params)).to be(nil)
      end
      it 'returns a button down' do
        expect(subject.button_down(params)).to match(/fa-chevron-down/)
      end
    end

    describe 'with second out of three piece justificative' do
      let(:index) { 1 }
      subject { type_de_champ_1.decorate }
      let(:button_up) { type_de_champ_1.decorate }

      it 'returns a button up' do
        expect(subject.button_up(params)).to match(/fa-chevron-up/)
      end
      it 'returns a button down' do
        expect(subject.button_down(params)).to match(/fa-chevron-down/)
      end
    end

    describe 'with last piece justificative' do
      let(:index) { 2 }
      subject { type_de_champ_2.decorate }
      let(:button_up) { type_de_champ_1.decorate }

      it 'returns a button up' do
        expect(subject.button_up(params)).to match(/fa-chevron-up/)
      end
      it 'returns a button down' do
        expect(subject.button_down(params)).to be(nil)
      end
    end
  end


end