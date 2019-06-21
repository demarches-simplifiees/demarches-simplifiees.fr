require 'spec_helper'

describe 'users/dossiers/qrcode.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_attestation) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'renders a summary of the attestation' do
    attestation_template = dossier.procedure.attestation_template
    expect(rendered).to have_text(attestation_template.build_body(dossier))
    expect(rendered).to have_text(attestation_template.build_title(dossier))
    expect(rendered).not_to have_text(attestation_template.footer)
  end
end
