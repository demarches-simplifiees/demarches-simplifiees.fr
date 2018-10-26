require 'spec_helper'

describe ProceduresDecorator do
  before do
    create(:procedure, :published,  created_at: Time.zone.local(2015, 12, 24, 14, 10))
    create(:procedure, :published,  created_at: Time.zone.local(2015, 12, 24, 14, 10))
    create(:procedure, :published,  created_at: Time.zone.local(2015, 12, 24, 14, 10))
  end

  let(:procedure) { Procedure.all.page(1) }

  subject { procedure.decorate }

  it { expect(subject.current_page).not_to be_nil }
  it { expect(subject.limit_value).not_to be_nil }
  it { expect(subject.count).to eq(3) }
  it { expect(subject.total_pages).not_to be_nil }
end
