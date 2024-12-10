# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dossiers::AutosaveFooterComponent, type: :component do
  subject(:component) { render_inline(described_class.new(dossier:, annotation:)) }

  let(:dossier) { create(:dossier) }
  let(:annotation) { false }

  context 'when showing brouillon state (default state)' do
    it 'displays brouillon explanation' do
      expect(component).to have_text("Votre brouillon")
    end
  end

  context 'when editing fork and can pass en construction' do
    let(:dossier) { create(:dossier, :en_construction).find_or_create_editing_fork(create(:user)) }

    it 'displays en construction explanation' do
      expect(component).to have_text("Vos modifications")
      expect(component).to have_text("Déposez-les")
    end

    context 'when dossier is not eligible' do
      before do
        allow(dossier).to receive(:can_passer_en_construction?).and_return(false)
      end

      it 'displays en construction explanation' do
        expect(component).to have_text("Vos modifications")
        expect(component).not_to have_text("Déposez-les")
      end
    end
  end

  context 'when showing annotations' do
    let(:annotation) { true }

    it 'displays annotations explanation' do
      expect(component).to have_text("Vos annotations")
    end
  end
end
