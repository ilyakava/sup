require 'spec_helper'

describe Member do
  let(:group) { Group.create!(name: 'Design') }
  let(:member) { Member.create!(name: 'John Doe', email: 'JD@ArtsyMail.com', group_ids: [group.id]) }
  context '#email' do
    it 'stores a lowercase version of #email' do
      expect(member.email).to eq 'jd@artsymail.com'.downcase
    end
  end

  context 'with an existing #email' do
    let(:member1) { Member.new }
    before do
      member1.name = member.name
      member1.email = member.email
      member1.group_ids = member.group_ids
    end

    it 'is not allowed' do
      expect do
        member1.save!
      end.to raise_error.with_message(/Email has already been taken/)
    end
    it 'does not allow case sensitive #email' do
      member1.email.upcase!
      expect do
        member1.save!
      end.to raise_error.with_message(/Email has already been taken/)
    end
  end
end
