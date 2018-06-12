require 'spec_helper'

describe Champ do
  require 'models/champ_shared_example.rb'

  it_should_behave_like "champ_spec"

  describe '#public?' do
    let(:type_de_champ) { build(:type_de_champ) }
    let(:champ) { type_de_champ.champ.build }

    it { expect(champ.public?).to be_truthy }
    it { expect(champ.private?).to be_falsey }
  end

  describe '#public_only' do
    let(:dossier) { create(:dossier) }

    it 'partition public and private' do
      expect(dossier.champs.count).to eq(1)
      expect(dossier.champs_private.count).to eq(1)
    end
  end

  describe '#format_datetime' do
    let(:type_de_champ) { build(:type_de_champ_datetime) }
    let(:champ) { type_de_champ.champ.build(value: value) }

    before { champ.save }

    context 'when the value is sent by a modern browser' do
      let(:value) { '2017-12-31 10:23' }

      it { expect(champ.value).to eq(value) }
    end

    context 'when the value is sent by a old browser' do
      let(:value) { '31/12/2018 09:26' }

      it { expect(champ.value).to eq('2018-12-31 09:26') }
    end
  end

  describe '#multiple_select_to_string' do
    let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list) }
    let(:champ) { type_de_champ.champ.build(value: value) }

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
    let(:type_de_champ) { create(:type_de_champ) }
    let(:champ) { type_de_champ.champ.build(value: value) }

    before { champ.save }

    context 'when type_de_champ is text' do
      let(:value) { '123' }

      it { expect(champ.for_export).to eq('123') }
    end

    context 'when type_de_champ is textarea' do
      let(:type_de_champ) { create(:type_de_champ_textarea) }
      let(:value) { '<b>gras<b>' }

      it { expect(champ.for_export).to eq('gras') }
    end

    context 'when type_de_champ is yes_no' do
      let(:type_de_champ) { create(:type_de_champ_yes_no) }

      context 'if yes' do
        let(:value) { 'true' }

        it { expect(champ.for_export).to eq('oui') }
      end

      context 'if no' do
        let(:value) { 'false' }

        it { expect(champ.for_export).to eq('non') }
      end

      context 'if nil' do
        let(:value) { nil }

        it { expect(champ.for_export).to eq(nil) }
      end
    end

    context 'when type_de_champ is multiple_drop_down_list' do
      let(:type_de_champ) { create(:type_de_champ_multiple_drop_down_list) }
      let(:value) { '["Crétinier", "Mousserie"]' }

      it { expect(champ.for_export).to eq('Crétinier, Mousserie') }
    end
  end

  describe '#enqueue_virus_check' do
    let(:champ) { type_de_champ.champ.build(value: nil) }

    context 'when type_champ is type_de_champ_piece_justificative' do
      let(:type_de_champ) { create(:type_de_champ_piece_justificative) }

      context 'and there is a blob' do
        before { champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain") }

        it { expect{ champ.save }.to change(VirusScan, :count).by(1) }
      end

      context 'and there is no blob' do
        it { expect{ champ.save }.to_not change(VirusScan, :count) }
      end
    end

    context 'when type_champ is not type_de_champ_piece_justificative' do
      let(:type_de_champ) { create(:type_de_champ_textarea) }

      it { expect{ champ.save }.to_not change(VirusScan, :count) }
    end
  end
end
