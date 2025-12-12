class Client < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  before_save :normalize_phone_number

  private

  def normalize_phone_number
    return if phone.blank?

    # Remove all non-numeric characters except +
    cleaned = phone.gsub(/[^\d+]/, "")

    # If already in E.164 format (+1XXXXXXXXXX), keep it
    return if cleaned.match?(/^\+1\d{10}$/)

    # If it's 10 digits (area code + number), add +1
    if cleaned.match?(/^\d{10}$/)
      self.phone = "+1#{cleaned}"
    # If it's 11 digits starting with 1, add +
    elsif cleaned.match?(/^1\d{10}$/)
      self.phone = "+#{cleaned}"
    # If it starts with + but not +1, keep as is (international)
    elsif cleaned.match?(/^\+\d+$/)
      self.phone = cleaned
    # Otherwise keep the cleaned version
    else
      self.phone = cleaned
    end
  end
end
