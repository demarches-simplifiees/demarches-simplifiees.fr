# frozen_string_literal: true

describe 'shared/avis/_list', type: :view do
  before { view.extend DossierHelper }

  subject { render 'shared/avis/list', avis: avis, avis_seen_at: seen_at, expert_or_instructeur: instructeur }

  let(:instructeur) { create(:instructeur) }
  let(:instructeur2) { create(:instructeur) }
  let(:introduction_file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }
  let(:expert) { create(:expert) }
  let!(:dossier) { create(:dossier) }
  let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: dossier.procedure) }
  let(:avis) { [create(:avis, claimant: instructeur, experts_procedure: experts_procedure, introduction_file: introduction_file)] }
  let(:seen_at) { avis.first.created_at + 1.hour }

  it { is_expected.to have_text(avis.first.introduction) }
  it { is_expected.not_to have_css(".highlighted") }

  context 'with a seen_at before avis created_at' do
    let(:seen_at) { avis.first.created_at - 1.hour }

    it { is_expected.to have_text("Fichier joint à la demande d’avis") }
    it { is_expected.to have_css(".highlighted") }
  end

  context 'with an answer' do
    let(:avis) { [create(:avis, :with_answer, claimant: instructeur, experts_procedure: experts_procedure)] }

    it 'renders the answer formatted with newlines' do
      expect(subject).to have_selector("p", text: avis.first.answer.split("\n").first)
      expect(subject).to have_selector("ul.list-style-type-none ul", count: 1) # avis.answer has two list item
      expect(subject).to have_selector("ul.list-style-type-none ul li", count: 2)
    end
  end

  context 'with another instructeur' do
    let(:avis) { [create(:avis, :with_answer, claimant: instructeur2, experts_procedure: experts_procedure, introduction_file: introduction_file)] }

    it 'shows the files attached to the avis request' do
      expect(subject).to have_text("Fichier joint à la demande d’avis")
    end
  end
end
