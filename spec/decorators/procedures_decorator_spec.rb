require 'spec_helper'

describe ProceduresDecorator do

  before do
    create(:procedure, :published,  created_at: Time.new(2015, 12, 24, 14, 10))
    create(:procedure, :published,  created_at: Time.new(2015, 12, 24, 14, 10))
    create(:procedure, :published,  created_at: Time.new(2015, 12, 24, 14, 10))
  end

  let(:procedure) { Procedure.all.paginate(page: 1) }

  subject { procedure.decorate }

  it { expect(subject.current_page).not_to be_nil }
  it { expect(subject.per_page).not_to be_nil }
  it { expect(subject.offset).not_to be_nil }
  it { expect(subject.total_entries).not_to be_nil }
  it { expect(subject.total_pages).not_to be_nil }
end