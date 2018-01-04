require 'spec_helper'

describe 'admin/attestation_templates/edit.html.haml', type: :view do
  let(:procedure) { create(:procedure) }
  let(:attestation_template) { create(:attestation_template, procedure: procedure) }
  let(:all_tags) { attestation_template.tags(reject_legacy: false) }

  before do
    allow(view).to receive(:admin_procedure_attestation_template_path).and_return("/toto")
    allow(view).to receive(:admin_procedure_attestation_template_preview_path).and_return("/toto")
    allow(view).to receive(:admin_procedure_attestation_template_disactivate_path).and_return("/toto")

    assign(:attestation_template, attestation_template)
    assign(:procedure, procedure)
  end

  subject { render }

  context "Legacy champs are not listed in the page" do
    it { expect(all_tags).to include(include({ libelle: 'numero_dossier', is_legacy: true })) }
    it { is_expected.not_to include("numero_dossier") }
  end

  context "Non-legacy champs are listed in the page" do
    it { expect(all_tags).to include(include({ libelle: 'numéro du dossier' })) }
    it { is_expected.to include("numéro du dossier") }
  end
end
