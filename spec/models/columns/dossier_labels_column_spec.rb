# frozen_string_literal: true

describe Columns::DossierLabelsColumn do
  describe '#sorted_ids' do
    let(:procedure) { create(:procedure, :published) }
    let(:column) { procedure.find_column(label: 'Labels') }

    let(:label_a) { Label.create(name: "a", color: 'green-bourgeon', procedure:) }
    let(:label_z) { Label.create(name: "z", color: 'green-bourgeon', procedure:) }
    let!(:dossier_z) { create(:dossier, procedure:) }
    let!(:dossier_a) { create(:dossier, procedure:) }
    let!(:dossier_no_label) { create(:dossier, procedure:) }
    let!(:dossier_label_a) { DossierLabel.create(dossier: dossier_a, label: label_a) }
    let!(:dossier_label_z) { DossierLabel.create(dossier: dossier_z, label: label_z) }

    subject { column.sorted_ids(procedure.dossiers, order) }

    context 'asc' do
      let(:order) { 'asc' }
      it { is_expected.to eq([dossier_a, dossier_z, dossier_no_label].map(&:id)) }
    end

    context 'desc' do
      let(:order) { 'desc' }
      it { is_expected.to eq([dossier_no_label, dossier_z, dossier_a].map(&:id)) }
    end
  end
end
