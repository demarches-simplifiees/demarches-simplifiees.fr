require 'spec_helper'

describe 'users/dossiers/qrcode.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_attestation) }
  let(:attestation) { dossier.procedure.attestation_template.render_attributes_for(dossier: dossier) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
    assign(:attestation, attestation)
  end

  subject! { render }

  it 'renders a summary of the attestation' do
    expect(rendered).to have_text(attestation[:body])
    expect(rendered).to have_text(attestation[:title])
    expect(rendered).not_to have_text(attestation[:footer])
  end
end
