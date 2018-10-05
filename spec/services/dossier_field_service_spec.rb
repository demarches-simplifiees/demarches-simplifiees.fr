require 'spec_helper'

describe DossierFieldService do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

  describe '#get_value' do
    subject { described_class.new.get_value(dossier, table, column) }

    context 'for self table' do
      let(:table) { 'self' }
      let(:column) { 'updated_at' } # All other columns work the same, no extra test required

      let(:dossier) { create(:dossier, procedure: procedure) }

      before { dossier.touch(time: DateTime.new(2018, 9, 25)) }

      it { is_expected.to eq(DateTime.new(2018, 9, 25)) }
    end

    context 'for user table' do
      let(:table) { 'user' }
      let(:column) { 'email' }

      let(:dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'bla@yopmail.com')) }

      it { is_expected.to eq('bla@yopmail.com') }
    end

    context 'for etablissement table' do
      let(:table) { 'etablissement' }
      let(:column) { 'code_postal' } # All other columns work the same, no extra test required

      let!(:dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75008')) }

      it { is_expected.to eq('75008') }
    end

    context 'for type_de_champ table' do
      let(:table) { 'type_de_champ' }
      let(:column) { procedure.types_de_champ.first.id.to_s }

      let(:dossier) { create(:dossier, procedure: procedure) }

      before { dossier.champs.first.update(value: 'kale') }

      it { is_expected.to eq('kale') }
    end

    context 'for type_de_champ_private table' do
      let(:table) { 'type_de_champ_private' }
      let(:column) { procedure.types_de_champ_private.first.id.to_s }

      let(:dossier) { create(:dossier, procedure: procedure) }

      before { dossier.champs_private.first.update(value: 'quinoa') }

      it { is_expected.to eq('quinoa') }
    end
  end
end
