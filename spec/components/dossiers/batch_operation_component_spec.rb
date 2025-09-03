# frozen_string_literal: true

RSpec.describe Dossiers::BatchOperationComponent, type: :component do
  include ActionView::Context
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  let(:component) do
    cmp = nil
    form_for(BatchOperation.new, url: Rails.application.routes.url_helpers.instructeur_batch_operations_path(procedure_id: 1), method: :post, data: { controller: 'batch-operation' }) do |_form|
      cmp = described_class.new(statut: statut, procedure: procedure)
    end
    cmp
  end

  let(:user) { create(:user) }
  let(:procedure) { create(:procedure) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  subject { render_inline(component).to_html }
  context 'statut traite' do
    let(:statut) { 'traites' }
    it { is_expected.to have_button('Archiver les dossiers', disabled: true) }
  end

  subject { render_inline(component).to_html }
  context 'statut suivis' do
    let(:statut) { 'suivis' }

    it do
      is_expected.to have_button('Passer les dossiers en instruction', disabled: true)
      is_expected.to have_button('Instruire les dossiers', disabled: true)
      is_expected.to have_button('Autres actions multiples', disabled: true)
      is_expected.to have_button('Repasser les dossiers en construction', disabled: true)
      is_expected.to have_button('Ne plus suivre les dossiers', disabled: true)
      is_expected.to have_button('Demander un avis externe', disabled: true)
      is_expected.to have_button('Envoyer un message aux usagers', disabled: true)
    end

    context 'with expert review disallowed procedure' do
      before {
        procedure.update!(allow_expert_review: false)
      }
      it do
        is_expected.to have_button('Passer les dossiers en instruction', disabled: true)
        is_expected.to have_button('Instruire les dossiers', disabled: true)
        is_expected.to have_button('Autres actions multiples', disabled: true)
        is_expected.to have_button('Repasser les dossiers en construction', disabled: true)
        is_expected.to have_button('Ne plus suivre les dossiers', disabled: true)
        is_expected.not_to have_button('Demander un avis externe', disabled: true)
      end
    end
  end

  context 'statut a-suivre' do
    let(:statut) { 'a-suivre' }
    it { is_expected.to have_button('Suivre les dossiers', disabled: true) }
  end

  context 'statut tous' do
    let(:statut) { 'tous' }
    it do
      is_expected.to have_button('Envoyer un message aux usagers', disabled: true)
    end
  end
end
