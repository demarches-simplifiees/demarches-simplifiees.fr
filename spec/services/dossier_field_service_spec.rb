require 'spec_helper'

describe DossierFieldService do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

  describe '#sorted_ids' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:assign_to) { create(:assign_to, procedure: procedure, gestionnaire: gestionnaire) }
    let(:sort) { { 'table' => table, 'column' => column, 'order' => order } }
    let(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to, sort: sort) }

    subject { described_class.new.sorted_ids(procedure.dossiers, procedure_presentation, gestionnaire) }

    context 'for notifications table' do
      let(:table) { 'notifications' }
      let(:column) { 'notifications' }

      let!(:notified_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:recent_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:older_dossier) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        notified_dossier.champs.first.touch(time: DateTime.new(2018, 9, 20))
        create(:follow, gestionnaire: gestionnaire, dossier: notified_dossier, demande_seen_at: DateTime.new(2018, 9, 10))
        recent_dossier.touch(time: DateTime.new(2018, 9, 25))
        older_dossier.touch(time: DateTime.new(2018, 5, 13))
      end

      context 'in ascending order' do
        let(:order) { 'asc' }

        it { is_expected.to eq([older_dossier, recent_dossier, notified_dossier].map(&:id)) }
      end

      context 'in descending order' do
        let(:order) { 'desc' }

        it { is_expected.to eq([notified_dossier, recent_dossier, older_dossier].map(&:id)) }
      end
    end

    context 'for self table' do
      let(:table) { 'self' }
      let(:column) { 'updated_at' } # All other columns work the same, no extra test required
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let(:recent_dossier) { create(:dossier, procedure: procedure) }
      let(:older_dossier) { create(:dossier, procedure: procedure) }

      before do
        recent_dossier.touch(time: DateTime.new(2018, 9, 25))
        older_dossier.touch(time: DateTime.new(2018, 5, 13))
      end

      it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
    end

    context 'for type_de_champ table' do
      let(:table) { 'type_de_champ' }
      let(:column) { procedure.types_de_champ.first.id.to_s }
      let(:order) { 'desc' } # Asc works the same, no extra test required

      let(:beurre_dossier) { create(:dossier, procedure: procedure) }
      let(:tartine_dossier) { create(:dossier, procedure: procedure) }

      before do
        beurre_dossier.champs.first.update(value: 'beurre')
        tartine_dossier.champs.first.update(value: 'tartine')
      end

      it { is_expected.to eq([tartine_dossier, beurre_dossier].map(&:id)) }
    end

    context 'for type_de_champ_private table' do
      let(:table) { 'type_de_champ_private' }
      let(:column) { procedure.types_de_champ_private.first.id.to_s }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let(:biere_dossier) { create(:dossier, procedure: procedure) }
      let(:vin_dossier) { create(:dossier, procedure: procedure) }

      before do
        biere_dossier.champs_private.first.update(value: 'biere')
        vin_dossier.champs_private.first.update(value: 'vin')
      end

      it { is_expected.to eq([biere_dossier, vin_dossier].map(&:id)) }
    end

    context 'for other tables' do
      # All other columns and tables work the same so it’s ok to test only one
      let(:table) { 'etablissement' }
      let(:column) { 'code_postal' }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let!(:huitieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75008')) }
      let!(:vingtieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75020')) }

      it { is_expected.to eq([huitieme_dossier, vingtieme_dossier].map(&:id)) }
    end
  end

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
