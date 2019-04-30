require 'spec_helper'

describe 'admin/mail_templates/edit.html.haml', type: :view do
  let(:procedure) { create(:procedure) }
  let(:mail_template) { create(:received_mail, procedure: procedure) }
  let(:all_tags) { mail_template.tags }

  before do
    allow(view).to receive(:admin_procedure_mail_template_path).and_return("/toto")
    allow(view).to receive(:admin_procedure_mail_templates_path).and_return("/toto")

    assign(:mail_template, mail_template)
    assign(:procedure, procedure)
  end

  context "Champs are listed in the page" do
    it { expect(all_tags).to include(include({ libelle: 'numéro du dossier' })) }
    it { expect(render).to include("numéro du dossier") }
  end
end
