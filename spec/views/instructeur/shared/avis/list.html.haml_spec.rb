require 'spec_helper'

describe 'gestionnaires/shared/avis/_list.html.haml', type: :view do
  before { view.extend DossierHelper }

  subject { render 'gestionnaires/shared/avis/list.html.haml', avis: avis, avis_seen_at: seen_at, current_gestionnaire: gestionnaire }

  let(:gestionnaire) { create(:gestionnaire) }
  let(:avis) { [create(:avis, claimant: gestionnaire)] }
  let(:seen_at) { avis.first.created_at + 1.hour }

  it { is_expected.to have_text(avis.first.introduction) }
  it { is_expected.not_to have_css(".highlighted") }

  context 'with a seen_at before avis created_at' do
    let(:seen_at) { avis.first.created_at - 1.hour }

    it { is_expected.to have_css(".highlighted") }
  end

  context 'with an answer' do
    let(:avis) { [create(:avis, :with_answer, claimant: gestionnaire)] }

    it 'renders the answer formatted with newlines' do
      expect(subject).to include(simple_format(avis.first.answer))
    end
  end
end
