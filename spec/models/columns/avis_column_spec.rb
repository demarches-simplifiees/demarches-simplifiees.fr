# frozen_string_literal: true

describe Columns::AvisColumn do
  describe '#sorted_ids' do
    let(:procedure) { create(:procedure, :published) }
    let(:column) { procedure.find_column(label: 'Avis oui/non') }

    let!(:dossier_yes) { create(:dossier, procedure:) }
    let!(:dossier_no) { create(:dossier, procedure:) }

    before do
      create_list(:avis, 2, dossier: dossier_yes, question_answer: true)
      create(:avis, dossier: dossier_no, question_answer: true)
      create(:avis, dossier: dossier_no, question_answer: false)
    end

    it { expect(column.sorted_ids(procedure.dossiers, 'asc')).to eq([dossier_no, dossier_yes].map(&:id)) }
  end
end
