require 'active_record'
require 'discretion'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Staff < ApplicationRecord
  self.table_name = 'staff'
  has_many :donations, dependent: :destroy

  use_discretion

  # Only logged-in Staff can see Staff emails.
  discreetly_read(:email) do |viewer, _record|
    viewer.is_a?(Staff)
  end

  private

  def can_see?(viewer)
    return true if Discretion.in_test?

    # Everyone can see Staff as long as they're logged-in.
    viewer.present?
  end

  def can_write?(viewer, _changes, new_record)
    return true if new_record
    return true if Discretion.in_test?

    # Only the staff themselves should be able to write.
    viewer.is_a?(Staff) && viewer&.id == id
  end

  def can_destroy?(_viewer)
    return true if Discretion.in_test?

    # No one can delete a Staff record.
    false
  end
end

class Donor < ApplicationRecord
  has_many :donations, dependent: :destroy

  use_discretion

  # Only logged-in Donors can see their own emails.
  discreetly_read(:email) do |viewer, record|
    viewer == record
  end

  private

  def can_see?(viewer)
    return true if Discretion.in_test?

    # Only the Donor herself or Staff of the organization can see the Donor.

    viewer.is_a?(Staff) || viewer&.id == id
  end

  def can_write?(viewer, _changes, new_record)
    return true if Discretion.in_test?

    # Only Staff can create a new Donor or, ironically, when someone
    # is not logged-in (e.g. in sign up flow).
    return viewer.nil? || viewer.is_a?(Staff) if new_record

    # Only the donor should be able to edit their details.
    viewer.is_a?(Donor) && viewer&.id == id
  end
end

class Donation < ApplicationRecord
  belongs_to :recipient, class_name: 'Staff', foreign_key: 'staff_id'
  belongs_to :donor, class_name: 'Donor', foreign_key: 'donor_id'

  use_discretion

  private

  def can_see?(viewer)
    return true if Discretion.in_test?

    # Only the donor or any Staff can see donations.
    (viewer&.is_a?(Donor) && viewer&.id == donor.id) || viewer&.is_a?(Staff)
  end

  def can_destroy?(viewer)
    return true if Discretion.in_test?

    # Once a donation is created, it cannot be destroyed, except maybe by a super user/admin
    # (not implemented).
    false
  end

  def can_write?(viewer, changes, new_record)
    return true if Discretion.in_test?

    # The recipient or the donor can create the donation.
    if new_record
      return (viewer&.is_a?(Donor) && viewer&.id == donor.id) ||
        (viewer&.is_a?(Staff) && viewer&.id == recipient.id)
    end

    # Only the donor can edit the donor_note.
    if changes.include?(:donor_note)
      return false unless viewer&.is_a?(Donor) && viewer&.id == donor.id
    end

    # Only the recipient can edit the recipient_note.
    if changes.include?(:recipient_note)
      return false unless viewer&.is_a?(Staff) && viewer&.id == recipient.id
    end

    # The amount can only be changed by the donor.
    if changes.include?(:amount)
      return false unless viewer&.is_a?(Donor) && viewer&.id == donor.id
    end

    can_see?(viewer)
  end
end
