# frozen_string_literal: true

require 'spec_helper'

describe 'users/dossiers/qrcode.html.haml', type: :view do
  context "no dossier" do
    before do
      sign_in create(:user)
    end

    subject! { render }

    it 'renders an error' do
      expect(rendered).to have_text(t('users.dossiers.no_dossier'))
    end
  end

  context "with dossier" do
    let(:dossier) { create(:dossier, :with_attestation) }

    context "with attestation" do
      let(:attestation) { dossier.attestation_template.render_attributes_for(dossier: dossier) }

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

    context "without attestation" do
      before do
        sign_in dossier.user
        assign(:dossier, dossier)
      end

      subject! { render }

      it 'renders a summary of the attestation' do
        expect(rendered).to have_text(t('users.dossiers.invalid_qrcode'))
      end
    end
  end
end
