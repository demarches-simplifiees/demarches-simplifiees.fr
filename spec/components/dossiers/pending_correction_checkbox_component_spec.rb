# frozen_string_literal: true

RSpec.describe Dossiers::PendingCorrectionCheckboxComponent, type: :component do
  subject { render_inline(described_class.new(dossier:)) }

  let(:procedure) { create(:procedure) }
  let(:dossier) { create(:dossier, :en_construction, procedure:) }

  context 'when dossier has no pending correction' do
    it 'renders nothing' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when dossier has pending correction' do
    before do
      create(:dossier_correction, dossier:)
    end

    it 'renders nothing' do
      expect(subject.to_html).to be_empty
    end

    context 'when procedure is sva' do
      let(:procedure) { create(:procedure, :sva) }

      it 'renders a checkbox' do
        expect(subject).to have_selector('input[type="checkbox"][name="dossier[pending_correction]"]')
      end

      context 'when there are error on checkbox' do
        before do
          dossier.errors.add(:pending_correction, :blank)
        end

        it 'renders the error' do
          expect(subject).to have_content("Cochez la case")
          expect(subject).to have_selector('.fr-checkbox-group--error')
        end
      end
    end
  end
end
