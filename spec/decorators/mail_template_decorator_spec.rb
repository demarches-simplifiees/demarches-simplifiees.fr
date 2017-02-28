require 'spec_helper'

describe MailTemplateDecorator do
  let(:mail_template) {create :mail_template}
  let(:decorator) { mail_template.decorate }

  context '#name' do
    subject { decorator.name }

    context 'when mail_template is a MailReceived' do
      let(:mail_template) {create :mail_template, :dossier_received}
      it { is_expected.to eq "E-mail d'accusé de réception" }
    end

  end

end
