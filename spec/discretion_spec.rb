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
    let(:donation1) { Donation.create!(donor: donor1, recipient: staff1, amount: 100.00) }

    context 'bypassing' do
      context 'omnisciently' do
        it 'should correctly set viewer during and after' do
          Discretion.set_current_viewer(staff1)
          Discretion.omnisciently do
            expect(Discretion.current_viewer).to eq(Discretion::OMNISCIENT_VIEWER)
          end
          expect(Discretion.current_viewer).to eq(staff1)
        end
      end

      context 'omnipotently' do
        it 'should correctly set viewer during and after' do
          Discretion.set_current_viewer(staff1)
          Discretion.omnipotently do
            expect(Discretion.current_viewer).to eq(Discretion::OMNIPOTENT_VIEWER)
          end
          expect(Discretion.current_viewer).to eq(staff1)
        end
      end
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

        context 'omnisciently' do
          it 'should be allowed for even a nil viewer' do
            Discretion.set_current_viewer(nil)
            pretend_not_in_test
            s1 = Discretion.omnisciently do
              staff1
            end
            expect(s1).not_to be nil
          end
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

        context 'omnisciently' do
          it 'should be allowed even for a nil viewer' do
            Discretion.set_current_viewer(nil)
            pretend_not_in_test
            d1 = Discretion.omnisciently do
              donor1
            end
            expect(d1).not_to be nil
          end
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

        it 'should be allowed for other staff' do
          donation1
          Discretion.set_current_viewer(staff2)
          pretend_not_in_test
          expect(donation1.reload).not_to be nil
        end

        it 'should not be allowed for other donors' do
          donation1
          Discretion.set_current_viewer(donor2)
          pretend_not_in_test
          expect { donation1.reload }.to raise_error(Discretion::CannotSeeError)
        end

        context 'omnisciently' do
          it 'should be allowed even for a nil viewer' do
            donation1
            Discretion.set_current_viewer(nil)
            pretend_not_in_test
            d1 = Discretion.omnisciently do
              donation1.reload
            end
            expect(d1).not_to be nil
          end
        end
      end
    end

    context 'creating' do
      context 'donations' do
        it 'should only be allowed by the donor or recipient' do
          Discretion.set_current_viewer(staff2)
          pretend_not_in_test
          expect { donation1 }.to raise_error(Discretion::CannotWriteError)
        end

        it 'should be allowed by donor' do
          Discretion.set_current_viewer(donor1)
          pretend_not_in_test
          expect(donation1).not_to be nil
        end

        it 'should be allowed by recipient' do
          Discretion.set_current_viewer(staff1)
          pretend_not_in_test
          expect(donation1).not_to be nil
        end

        context 'omnisciently' do
          it 'should not be allowed by a nil viewer' do
            Discretion.set_current_viewer(nil)
            pretend_not_in_test
            expect {
              Discretion.omnisciently do
                donation1
              end
            }.to raise_error(Discretion::CannotWriteError)
          end
        end

        context 'omnipotently' do
          it 'should be allowed by a nil viewer' do
            Discretion.set_current_viewer(nil)
            pretend_not_in_test
            d1 = Discretion.omnipotently { donation1 }
            expect(d1).not_to be nil
          end
        end
      end
    end

    context 'editing' do
      context 'donations' do
        it 'should be allowed if donor is editing the donor_note' do
          Discretion.set_current_viewer(donor1)
          donation1
          pretend_not_in_test
          expect(donation1.update(donor_note: 'Hello!')).to be true
        end

        it 'should be allowed if donor is editing the amount' do
          Discretion.set_current_viewer(donor1)
          donation1
          pretend_not_in_test
          expect(donation1.update(amount: donation1.amount + 1.0)).to be true
        end

        it 'should be allowed if recipient is editing the recipient_note' do
          Discretion.set_current_viewer(staff1)
          donation1
          pretend_not_in_test
          expect(donation1.update(recipient_note: 'Thanks!')).to be true
        end

        it 'should not be allowed if staff is trying to edit the donor_note.' do
          Discretion.set_current_viewer(staff1)
          donation1
          pretend_not_in_test
          expect { donation1.update(donor_note: 'Hmmm') }.to raise_error(Discretion::CannotWriteError)
        end

        context 'omnisciently' do
          it 'should not be allowed by a nil viewer' do
            Discretion.set_current_viewer(nil)
            donation1
            pretend_not_in_test
            expect {
              Discretion.omnisciently do
                donation1.update(donor_note: 'Hmmmmmm')
              end
            }.to raise_error(Discretion::CannotWriteError)
          end
        end

        context 'omnipotently' do
          it 'should be allowed by a nil viewer' do
            Discretion.set_current_viewer(nil)
            donation1
            pretend_not_in_test
            ret = Discretion.omnipotently do
              donation1.update(donor_note: 'Hmmmmmm')
            end
            expect(ret).to be true
          end
        end
      end
    end
  end
end
