require 'rspec'

describe PhoneSyntaxCheckerService do
  describe '#check_france_number' do
    subject { PhoneSyntaxCheckerService.is_france_number?(pn) }

    expected_values = {
      '06123456': false,
      '06123456789': false,
      '0712345678': true,
      '0612345678': true,
      '0512345678': true,
      '0412345678': true,
      '0312345678': true,
      '0212345678': true,
      '0112345678': true,
      '0812345678': false,
      '+33 0612345678': false,
      '+33 612345678': true,
      '(+33) 612345678': true,
      '(33) 612345678': true,
      '(33) 6 1234 5678': true,
      '(33) 6 12-34 56-78': true,
      '(33) 6 12.34 56.78': true,

      '06 1234 5678': true,
      '06 12-34 56-78': true,
      '06 12.34 56.78': true
    }
    expected_values.each do |val, expected|
      it "returns #{expected} when number is #{val}" do
        result = PhoneSyntaxCheckerService.is_france_number?(val)
        expect(result).to eq(expected)
      end
    end
  end

  describe '#check_polynesian_number' do
    expected_values = {
      '06123456': false,
      '06123456789': false,
      '40123456': true,
      '49123456': true,
      '87123456': true,
      '88123456': true,
      '89123456': true,
      '90123456': false,
      '41123456': false,
      '123456': false,
      '123456789': false,
      '(689)87123456': true,
      '(+689)87123456': true,
      '(+689) 87123456': true,
      '(+689) 87 12 34 56': true,
      '(+689) 87-12.34-56': true,
      '87 12 34 56': true,
      '87-12.34-56': true
    }
    expected_values.each do |val, expected|
      it "returns #{expected} when number is #{val}" do
        result = PhoneSyntaxCheckerService.is_polynesian_number?(val)
        expect(result).to eq(expected)
      end
    end
  end

  describe '#check_french_or_polynesian_number' do
    expected_values = {
      '06123456': false,
      '06123456789': false,
      '40123456': true,
      '0712345678': true,
      '(+689)87123456': true,

      '0112345678': true,
      '0812345678': false,
      '+33 0612345678': false,
      '+33 612345678': true
    }
    expected_values.each do |val, expected|
      it "returns #{expected} when number is #{val}" do
        result = PhoneSyntaxCheckerService.is_french_or_polynesian_number?(val)
        expect(result).to eq(expected)
      end
    end
  end
end
