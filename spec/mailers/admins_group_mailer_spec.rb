RSpec.describe AdminsGroupMailer, type: :mailer do
  describe '#notify_added_admins_group_managers' do
    let(:admins_group) { create(:admins_group) }

    let(:admins_group_managers_to_add) { [create(:admins_group_manager, email: 'int3@g'), create(:admins_group_manager, email: 'int4@g')] }

    let(:current_super_admin_email) { 'toto@email.com' }

    subject { described_class.notify_added_admins_group_managers(admins_group, admins_group_managers_to_add, current_super_admin_email) }

    before { admins_group_managers_to_add.each { admins_group.add(_1) } }

    it { expect(subject.body).to include('Vous venez d’être nommé gestionnaire du groupe') }
    it { expect(subject.bcc).to match_array(['int3@g', 'int4@g']) }
  end
end
