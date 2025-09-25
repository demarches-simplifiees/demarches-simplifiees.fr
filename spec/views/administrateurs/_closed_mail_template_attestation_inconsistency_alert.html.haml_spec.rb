# frozen_string_literal: true

describe 'admin/_closed_mail_template_attestation_inconsistency_alert', type: :view do
  let(:procedure) { create(:procedure, closed_mail: closed_mail, attestation_acceptation_template:) }
  let(:attestation_acceptation_template) { nil }

  def alert
    assign(:procedure, procedure)
    render
    rendered
  end

  context 'when there is no inconsistency' do
    let(:closed_mail) { nil }

    it { expect(alert).to be_empty }
  end

  context 'when there is no active attestation but the closed mail template mentions one' do
    let(:closed_mail) { create(:closed_mail, body: '--lien attestation--') }

    it do
      expect(alert).to include("Cette démarche ne comporte pas d’attestation, mais l’accusé d’acceptation en mentionne une")
      expect(alert).to include(edit_admin_procedure_attestation_template_path(procedure))
      expect(alert).to include(edit_admin_procedure_mail_template_path(procedure, Mails::ClosedMail::SLUG))
    end
  end

  context 'when there is an active attestation but the closed mail template does not mention it' do
    let(:closed_mail) { create(:closed_mail) }
    let(:attestation_acceptation_template) { build(:attestation_template) }

    it do
      expect(alert).to include("Cette démarche comporte une attestation, mais l’accusé d’acceptation ne la mentionne pas")
      expect(alert).to include(edit_admin_procedure_mail_template_path(procedure, Mails::ClosedMail::SLUG))
    end

    context 'when the procedure has been published, the attestation cannot be deactivated' do
      let(:procedure) { create(:procedure, :published, closed_mail: closed_mail) }

      it do
        expect(procedure.locked?).to be_truthy
        expect(alert).not_to include(edit_admin_procedure_attestation_template_path(procedure))
      end
    end

    context 'when the procedure is still a draft' do
      it do
        expect(procedure.locked?).to be_falsey
        expect(alert).to include(edit_admin_procedure_attestation_template_path(procedure))
      end
    end
  end
end
