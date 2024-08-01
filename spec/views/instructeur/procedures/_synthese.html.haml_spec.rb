# frozen_string_literal: true

describe 'instructeurs/procedures/_synthese', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let!(:dossier) { create(:dossier, procedure: procedure) }

  context 'when instructeur has 2 procedures and 1 file, table is shown' do
    let(:procedure2) { create(:procedure) }

    subject {
      render 'instructeurs/procedures/synthese',
      all_dossiers_counts: {
        'à suivre': 0,
        'suivis': 0,
        'traités': 1,
        'dossiers': 1,
        'archivés': 0
      },
      procedures: [procedure, procedure2]
    }

    it { is_expected.to have_text('Synthèse des dossiers') }
    it { is_expected.not_to have_text('suivis') }
    it { is_expected.to have_text('traités') }
    it { is_expected.to have_text('dossiers') }
    it { is_expected.not_to have_text('archivés') }
  end

  context 'when instructeur has 1 procedure and 1 file, table is not shown' do
    subject {
      render 'instructeurs/procedures/synthese',
      all_dossiers_counts: {
        'à suivre': 0,
        'suivis': 0,
        'traités': 1,
        'dossiers': 1,
        'archivés': 0
      },
      procedures: [procedure]
    }

    it { is_expected.not_to have_text('Synthèse des dossiers') }
    it { is_expected.not_to have_text('suivis') }
    it { is_expected.not_to have_text('traités') }
    it { is_expected.not_to have_text('dossiers') }
    it { is_expected.not_to have_text('archivés') }
  end
end
