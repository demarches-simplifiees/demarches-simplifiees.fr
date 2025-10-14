# frozen_string_literal: true

describe 'admin/_mail_template_attestation_inconsistency_alert', type: :view do
  def render_alert(procedure, mail_type)
    state = procedure.mail_template_attestation_inconsistency_state(mail_type.to_sym)
    return '' if state.blank?

    assign(:procedure, procedure)
    render partial: 'admin/mail_template_attestation_inconsistency_alert',
           locals: { procedure:, state:, mail_type:, attestation_template_v1: false }
    rendered
  end

  context 'closed_mail / acceptation' do
    let(:mail_type) { 'acceptation' }

    context 'when there is no inconsistency' do
      let(:procedure) { create(:procedure, closed_mail: build(:closed_mail, body: '')) }

      it 'renders nothing' do
        expect(render_alert(procedure, mail_type)).to be_empty
      end
    end

    context 'when there is no active attestation but the mail template mentions one' do
      let(:mail) { create(:closed_mail, body: '--lien attestation--') }
      let(:procedure) { create(:procedure, closed_mail: mail, attestation_acceptation_template: nil) }

      it 'includes extraneous_tag alert text' do
        expect(render_alert(procedure, mail_type))
          .to include("Cette démarche ne comporte pas d’attestation, mais\nl’accusé d’acceptation\nen mentionne une")
      end

      it 'includes mail template edit link' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_mail_template_path(procedure, 'acceptation'))
      end

      it 'includes attestation edit link (V2 if needed)' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_attestation_template_v2_path(procedure, attestation_kind: :acceptation))
      end
    end

    context 'when there is an active attestation but the mail template does not mention it' do
      let(:mail) { create(:closed_mail) }
      let(:attestation) { build(:attestation_template, activated: true, kind: :acceptation) }
      let(:procedure) { create(:procedure, closed_mail: mail, attestation_acceptation_template: attestation) }

      it 'includes missing_tag alert text' do
        expect(render_alert(procedure, mail_type))
          .to include("Cette démarche comporte une attestation, mais\nl’accusé d’acceptation\nne la mentionne pas")
      end

      it 'includes mail template edit link' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_mail_template_path(procedure, 'acceptation'))
      end

      context 'when procedure is draft' do
        it 'can disable attestation' do
          expect(render_alert(procedure, mail_type))
            .to include(edit_admin_procedure_attestation_template_v2_path(procedure, attestation_kind: :acceptation))
        end
      end
    end
  end

  context 'refused_mail / refus' do
    let(:mail_type) { 'refus' }

    context 'when there is no inconsistency' do
      let(:procedure) { create(:procedure, refused_mail: build(:refused_mail, body: '')) }

      it 'renders nothing' do
        expect(render_alert(procedure, mail_type)).to be_empty
      end
    end

    context 'when there is no active attestation but the mail template mentions one' do
      let(:mail) { create(:refused_mail, body: '--lien attestation--') }
      let(:attestation) { build(:attestation_template, activated: false, kind: :refus) }
      let(:procedure) { create(:procedure, refused_mail: mail, attestation_refus_template: attestation) }

      it 'includes extraneous_tag alert text' do
        expect(render_alert(procedure, mail_type))
          .to include("Cette démarche ne comporte pas d’attestation, mais\nl’accusé de refus\nen mentionne une")
      end

      it 'includes mail template edit link' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_mail_template_path(procedure, 'refus'))
      end

      it 'includes attestation edit link' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_attestation_template_v2_path(procedure, attestation_kind: :refus))
      end
    end

    context 'when there is an active attestation but the mail template does not mention it' do
      let(:mail) { create(:refused_mail) }
      let(:attestation) { build(:attestation_template, activated: true, kind: :refus) }
      let(:procedure) { create(:procedure, refused_mail: mail, attestation_refus_template: attestation) }

      it 'includes missing_tag alert text' do
        expect(render_alert(procedure, mail_type))
          .to include("Cette démarche comporte une attestation, mais\nl’accusé de refus\nne la mentionne pas :")
      end

      it 'includes mail template edit link' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_mail_template_path(procedure, 'refus'))
      end

      it 'includes attestation edit link' do
        expect(render_alert(procedure, mail_type))
          .to include(edit_admin_procedure_attestation_template_v2_path(procedure, attestation_kind: :refus))
      end
    end
  end
end
