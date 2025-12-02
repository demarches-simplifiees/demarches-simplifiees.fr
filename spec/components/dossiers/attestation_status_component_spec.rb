# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dossiers::AttestationStatusComponent, type: :component do
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

  subject { render_inline(described_class.new(dossier: dossier)) }

  context 'when attestation exists' do
    before do
      create(:attestation, :with_pdf, dossier:)
    end

    it 'renders download button' do
      expect(subject.text).to include('Télécharger l’attestation')
    end
  end

  context 'when attestation does not exist but template is available' do
    before do
      template = create(:attestation_template, procedure:, state: :published)
      template.update!(updated_at: 1.day.ago)
    end

    it 'renders download button' do
      expect(subject.text).to include('Télécharger l’attestation')
    end
  end

  context 'when no template is configured' do
    it 'does not render' do
      expect(subject.to_html).to be_blank
    end
  end

  context 'when template is not activated' do
    before do
      create(:attestation_template, procedure:, state: :published, activated: false)
    end

    it 'does not render' do
      expect(subject.to_html).to be_blank
    end
  end

  context 'when dossier is refused with attestation' do
    let(:dossier) { create(:dossier, :refuse, procedure:) }

    before do
      procedure.attestation_refus_template = create(:attestation_template, :refus, procedure:, state: :published)
      create(:attestation, :with_pdf, dossier:)
    end

    it 'renders download button' do
      expect(subject.text).to include('Télécharger l’attestation')
    end
  end

  context 'when dossier is not in terminal state' do
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    it 'does not render' do
      expect(subject.to_html).to be_blank
    end
  end

  context 'when dossier is sans_suite' do
    let(:dossier) { create(:dossier, :sans_suite, procedure:) }

    it 'does not render' do
      expect(subject.to_html).to be_blank
    end
  end
end
