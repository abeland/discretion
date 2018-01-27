require 'rails_helper'

def pretend_not_in_test
  allow(Discretion).to receive(:in_test?).and_return(false)
end

def unpretend_not_in_test
  allow(Discretion).to receive(:in_test?).and_return(true)
end

RSpec.describe Discretion do
  context 'enforcement' do
    let(:staff1) { Staff.create!(name: 'John Owen') }
    let(:staff2) { Staff.create!(name: 'Paul of Tarsus') }
    let(:donor1) { Donor.create!(name: 'Justin Martyr') }
    let(:donor2) { Donor.create!(name: 'John Calvin') }
    let (:donation1) do
      Donation.create!(donor: donor1, recipient: staff1, amount: 100.00)
    end

    context 'viewing' do

      context 'staff' do
        it 'should be allowed for staff himself' do
          Discretion.set_current_viewer(staff1)
          pretend_not_in_test
          expect(staff1.reload).not_to be nil
        end

        it 'should be allowed for another staff' do
          Discretion.set_current_viewer(staff1)
          pretend_not_in_test
          expect(staff2).not_to be nil
        end

        it 'should not be allowed for a donor' do
          Discretion.set_current_viewer(donor1)
          pretend_not_in_test
          expect { staff1 }.to raise_error(Discretion::CannotSeeError)
        end
      end

      context 'donors' do
        it 'should be allowed for the donor' do
          Discretion.set_current_viewer(donor1)
          pretend_not_in_test
          expect(donor1.reload).not_to be nil
        end

        it 'should not be allowed for another donor' do
          Discretion.set_current_viewer(donor2)
          pretend_not_in_test
          expect { donor1 }.to raise_error(Discretion::CannotSeeError)
        end

        it 'should be allowed for staff' do
          Discretion.set_current_viewer(staff1)
          pretend_not_in_test
          expect(donor1).not_to be nil
          expect(donor2).not_to be nil

          unpretend_not_in_test

          Discretion.set_current_viewer(staff2)
          pretend_not_in_test
          expect(donor1.reload).not_to be nil
          expect(donor2.reload).not_to be nil
        end
      end

      context 'donations' do
        it 'should be allowed for the donor' do
          donation1
          Discretion.set_current_viewer(donor1)
          pretend_not_in_test
          expect(donation1.reload).not_to be nil
        end

        it 'should be allowed for the staff recipient' do
          Discretion.set_current_viewer(staff1)
          pretend_not_in_test
          expect(donation1).not_to be nil
        end

        it 'should not be allowed for other staff' do
          donation1
          Discretion.set_current_viewer(staff2)
          pretend_not_in_test
          expect { donation1.reload }.to raise_error(Discretion::CannotSeeError)
        end

        it 'should not be allowed for other donors' do
          donation1
          Discretion.set_current_viewer(donor2)
          pretend_not_in_test
          expect { donation1.reload }.to raise_error(Discretion::CannotSeeError)
        end
      end
    end

    context 'writing' do
      context 'donations' do
        it 'should be allowed by staff recipient' do
          Discretion.set_current_viewer(staff1)
          pretend_not_in_test
          expect(donation1).not_to be nil
        end

        it 'should not be allowed by another staff' do
          Discretion.set_current_viewer(staff2)
          pretend_not_in_test
          expect { donation1 }.to raise_error(Discretion::CannotWriteError)
        end

        it 'should not be allowed by a donor' do
          donation1
          Discretion.set_current_viewer(donor1)
          pretend_not_in_test
          expect {
            donation1.update!(amount: donation1.amount + 1.00)
          }.to raise_error(Discretion::CannotWriteError)
        end
      end
    end
  end
end
