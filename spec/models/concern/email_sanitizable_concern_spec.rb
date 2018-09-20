describe EmailSanitizableConcern, type: :model do
  describe 'sanitize_email' do
    let(:email_concern) do
      (Class.new do
        include EmailSanitizableConcern
        attr_accessor :email

        def initialize(email)
          self.email = email
        end

        def [](key)
          self.send(key)
        end

        def []=(key, value)
          self.send("#{key}=", value)
        end
      end).new(email)
    end

    before do
      email_concern.sanitize_email(:email)
    end

    context 'on an empty email' do
      let(:email) { '' }
      it { expect(email_concern.email).to eq('') }
    end

    context 'on a valid email' do
      let(:email) { 'michel@toto.fr' }
      it { expect(email_concern.email).to eq('michel@toto.fr') }
    end

    context 'on an email with trailing spaces' do
      let(:email) { ' michel@toto.fr    ' }
      it { expect(email_concern.email).to eq('michel@toto.fr') }
    end

    context 'on an email with trailing nbsp' do
      let(:email) { ' michel@toto.fr  ' }
      it { expect(email_concern.email).to eq('michel@toto.fr') }
    end

    context 'on an invalid email' do
      let(:email) { 'mich el@toto.fr' }
      it { expect(email_concern.email).to eq('mich el@toto.fr') }
    end
  end
end
