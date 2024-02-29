RSpec.describe BalancerDeliveryMethod do
  class ExampleMailer < ApplicationMailer
    def greet(name)
      mail(to: "smtp_to", from: "smtp_from", body: "Hello #{name}")
    end
  end

  class ImportantEmail < ApplicationMailer
    before_action :set_x_deliver_with

    def greet(name)
      mail(to: "smtp_to", from: "smtp_from", body: "Hello #{name}")
    end

    private

    def set_x_deliver_with
      headers['X-deliver-with'] = :mock_smtp
    end
  end

  class TestMail
    def self.deliveries
      @deliveries ||= []
    end

    def self.deliveries=(val)
      @deliveries = val
    end

    attr_accessor :settings

    def initialize(values)
      @settings = values.dup
    end

    def deliver!(mail)
      Mail::SmtpEnvelope.new(mail)
      self.class.deliveries << mail
    end
  end

  class MockSmtp < TestMail; end

  class MockSendmail < TestMail; end

  class FixedSequence
    def initialize(sequence)
      @enumerator = sequence.each
    end

    def rand(_)
      @enumerator.next
    end
  end

  before do
    ActionMailer::Base.add_delivery_method :mock_smtp, MockSmtp
    ActionMailer::Base.add_delivery_method :mock_sendmail, MockSendmail
    ActionMailer::Base.add_delivery_method :balancer, BalancerDeliveryMethod

    ExampleMailer.delivery_method = :balancer
    ImportantEmail.delivery_method = :balancer
  end

  context 'when a single delivery method is provided' do
    before do
      ActionMailer::Base.balancer_settings = { mock_smtp: 10 }
    end

    it 'sends emails to the selected delivery method' do
      mail = ExampleMailer.greet('Joshua').deliver_now
      expect(mail).to have_been_delivered_using(MockSmtp)
    end
  end

  context 'when multiple delivery methods are provided' do
    before do
      ActionMailer::Base.balancer_settings = { mock_smtp: 10, mock_sendmail: 5 }

      rng_sequence = [3, 14, 1]
      BalancerDeliveryMethod.random = FixedSequence.new(rng_sequence)
    end

    after do
      BalancerDeliveryMethod.random = Random.new
    end

    it 'sends emails randomly, given the provided weights' do
      mail1 = ExampleMailer.greet('Lucia').deliver_now
      expect(mail1).to have_been_delivered_using(MockSmtp)

      mail2 = ExampleMailer.greet('Damian').deliver_now
      expect(mail2).to have_been_delivered_using(MockSendmail)

      mail3 = ExampleMailer.greet('Rahwa').deliver_now
      expect(mail3).to have_been_delivered_using(MockSmtp)
    end
  end

  context 'when observers are configured' do
    let(:observer) { double("Observer") }

    before do
      allow(observer).to receive(:delivered_email)
      ActionMailer::Base.register_observer(observer)
    end

    after do
      ActionMailer::Base.unregister_observer(observer)
    end

    it 'invoke the observer exactly once' do
      mail = ExampleMailer.greet('Joshua').deliver_now
      expect(observer).to have_received(:delivered_email).with(mail).once
    end
  end

  context 'SafeMailer.important_email_use_delivery_method is present' do
    before do
      allow(SafeMailer).to receive(:important_email_use_delivery_method).and_return(delivery_method)
      ActionMailer::Base.balancer_settings = { mock_smtp: 10, mock_sendmail: 5 }

      rng_sequence = [3, 14, 1]
      BalancerDeliveryMethod.random = FixedSequence.new(rng_sequence)
    end

    after do
      BalancerDeliveryMethod.random = Random.new
    end

    context 'known delivery_method & email is important' do
      let(:delivery_method) { :mock_smtp }

      it 'sends emails given the forced_delivery_method' do
        mail1 = ImportantEmail.greet('Lucia').deliver_now
        expect(mail1).to have_been_delivered_using(MockSmtp)

        mail2 = ImportantEmail.greet('Damian').deliver_now
        expect(mail2).to have_been_delivered_using(MockSmtp)

        mail3 = ImportantEmail.greet('Rahwa').deliver_now
        expect(mail3).to have_been_delivered_using(MockSmtp)
      end
    end
  end

  # Helpers

  def have_been_delivered_using(delivery_class)
    satisfy("have been delivered using #{delivery_class}") do |mail|
      delivery_class.deliveries.include?(mail)
    end
  end
end
