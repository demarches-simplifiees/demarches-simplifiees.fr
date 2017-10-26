require 'spec_helper'

describe Champ do
  require 'models/champ_shared_example.rb'

  it_should_behave_like "champ_spec"

  describe '#serialize_datetime_if_needed' do
    let(:type_de_champ) { TypeDeChamp.new(type_champ: 'datetime') }
    let(:champ) { Champ.new(type_de_champ: type_de_champ, value: value) }

    before { champ.save }

    # when using the old form, and the ChampsService Class
    # TODO: to remove
    context 'when the value is already serialized' do
      let(:value) { '12/01/2017 10:23' }

      it { expect(champ.value).to eq(value) }
    end

    context 'when the value is not already serialized' do
      let(:value) { '{ 1=>2017, 2=>01, 3=>12, 4=>10, 5=>23  }' }

      it { expect(champ.value).to eq('12/01/2017 10:23') }
    end
  end

  describe '#multiple_select_to_string' do
    let(:type_de_champ) { TypeDeChamp.new(type_champ: 'multiple_drop_down_list') }
    let(:champ) { Champ.new(type_de_champ: type_de_champ, value: value) }

    before { champ.save }

    # when using the old form, and the ChampsService Class
    # TODO: to remove
    context 'when the value is already deserialized' do
      let(:value) { '["1", "2"]' }

      it { expect(champ.value).to eq(value) }

      context 'when the value is nil' do
        let(:value) { nil }

        it { expect(champ.value).to eq(value) }
      end
    end

    # for explanation for the "" entry, see
    # https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/select
    # GOTCHA
    context 'when the value is not already deserialized' do
      context 'when a choice is selected' do
        let(:value) { '["", "1", "2"]' }

        it { expect(champ.value).to eq('["1", "2"]') }
      end

      context 'when all choices are removed' do
        let(:value) { '[""]' }

        it { expect(champ.value).to eq(nil) }
      end
    end
  end

  describe 'for_export' do
    let(:type_de_champ) { create(:type_de_champ_public, type_champ: type_champ) }
    let(:champ) { Champ.new(type_de_champ: type_de_champ, value: value) }

    before { champ.save }

    context 'when type_de_champ is text' do
      let(:type_champ) { 'text' }
      let(:value) { '123' }

      it { expect(champ.for_export).to eq('123') }
    end

    context 'when type_de_champ is textarea' do
      let(:type_champ) { 'textarea' }
      let(:value) { '<b>gras<b>' }

      it { expect(champ.for_export).to eq('gras') }
    end

    context 'when type_de_champ is yes_no' do
      let(:type_champ) { 'yes_no' }

      context 'if yes' do
        let(:value) { 'yes' }

        it { expect(champ.for_export).to eq('oui') }
      end

      context 'if no' do
        let(:value) { 'no' }

        it { expect(champ.for_export).to eq('non') }
      end
    end
  end
end
