require 'spec_helper'

describe MailTemplateDecorator do
  let(:mail_template) {create :mail_template}
  let(:decorator) { mail_template.decorate }

  context '#name' do
    subject { decorator.name }

    it { is_expected.to eq decorator.type}

    context 'when mail_template is a MailReceived' do
      let(:mail_template) {create :mail_template, :dossier_received}
      it { is_expected.to eq "Email d'accusé de réception" }
    end

  end

end
