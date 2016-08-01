require 'spec_helper'

describe WelcomeMailer, type: :mailer do
  describe ".welcome_email" do
    let(:user) { create(:user) }
    subject(:subject) { described_class.welcome_email(user) }
    it { expect(subject.body).to match(root_url) }
    it { expect(subject.body).to match(new_user_password_url) }
    it { expect(subject.body).to match(user.email) }
    it { expect(subject.body).to match('Bienvenue sur la plateforme TPS') }
    it { expect(subject.body).to match('Nous vous remercions de vous être inscrit sur TPS. Pour mémoire, voici quelques informations utiles :')}

    it { expect(subject.subject).to eq("Création de votre compte TPS") }
  end
end
