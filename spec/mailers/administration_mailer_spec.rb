RSpec.describe AdministrationMailer, type: :mailer do
  describe '#new_admin_email' do
    let(:admin) { create(:administrateur) }
    let(:administration) { create(:administration) }

    subject { described_class.new_admin_email(admin, administration) }

    it { expect(subject.subject).not_to be_empty }
  end

  describe '#invite_admin' do
    let(:admin) { create(:administrateur) }
    let(:token) { "Toc toc toc" }
    let(:administration_id) { BizDev::BIZ_DEV_IDS.first }

    subject { described_class.invite_admin(admin, token, administration_id) }

    it { expect(subject.subject).not_to be_empty }
  end

  describe '#refuse_admin' do
    let(:mail) { "l33t-4dm1n@h4x0r.com" }

    subject { described_class.refuse_admin(mail) }

    it { expect(subject.subject).not_to be_empty }
  end

  describe '#dubious_procedures' do
    let(:procedures_and_type_de_champs) { [] }

    subject { described_class.dubious_procedures(procedures_and_type_de_champs) }

    it { expect(subject.subject).not_to be_empty }
  end
end
