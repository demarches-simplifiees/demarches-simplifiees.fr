describe Utils::Retryable do
  Includer = Struct.new(:something) do
    include Utils::Retryable

    def caller(max_attempt:, errors:)
      with_retry(max_attempt: max_attempt, errors: errors) do
        yield
      end
    end
  end

  subject { Includer.new("test") }
  let(:spy) { double() }

  describe '#with_retry' do
    it 'works while retry count is less than max attempts' do
      divider_that_raise_error = 0
      divider_that_works = 1
      expect(spy).to receive(:divider).and_return(divider_that_raise_error, divider_that_works)
      result = subject.caller(max_attempt: 2, errors: [ZeroDivisionError]) { 10 / spy.divider }
      expect(result).to eq(10 / divider_that_works)
    end

    it 're raise error if it occures more than max_attempt' do
      expect(spy).to receive(:divider).and_return(0, 0)
      expect { subject.caller(max_attempt: 1, errors: [ZeroDivisionError]) { 0 / spy.divider } }
        .to raise_error(ZeroDivisionError)
    end

    it 'does not retry other errors' do
      expect(spy).to receive(:divider).and_raise(StandardError).once
      expect { subject.caller(max_attempt: 2, errors: [ZeroDivisionError]) { 0 / spy.divider } }
        .to raise_error(StandardError)
    end
  end
end
