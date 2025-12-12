class Client < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  before_save :normalize_data

  private

  def normalize_data
    normalize_email
    normalize_name
    normalize_phone_number
  end

  def normalize_email
    return if email.blank?

    # Lowercase, strip whitespace, remove common speech-to-text errors
    self.email = email.to_s
      .downcase
      .strip
      .gsub(/\s*at\s*/, "@")  # "user at example" -> "user@example"
      .gsub(/\s*dot\s*/, ".")  # "example dot com" -> "example.com"
      .gsub(/\s+/, "")  # Remove all remaining spaces
  end

  def normalize_name
    return if name.blank?

    # Titlecase, strip extra whitespace
    self.name = name.to_s
      .strip
      .gsub(/\s+/, " ")  # Collapse multiple spaces to one
      .split
      .map(&:capitalize)  # Capitalize each word
      .join(" ")
  end

  def normalize_phone_number
    return if phone.blank?

    # Convert words to digits for voice input
    phone_with_digits = convert_words_to_digits(phone)

    # Remove all non-numeric characters except +
    cleaned = phone_with_digits.gsub(/[^\d+]/, "")

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

  def convert_words_to_digits(text)
    word_to_digit = {
      "zero" => "0", "oh" => "0",
      "one" => "1",
      "two" => "2", "to" => "2", "too" => "2",
      "three" => "3", "tree" => "3",
      "four" => "4", "for" => "4",
      "five" => "5",
      "six" => "6",
      "seven" => "7",
      "eight" => "8", "ate" => "8",
      "nine" => "9", "niner" => "9"
    }

    text.downcase.split.map { |word| word_to_digit[word] || word }.join
  end
end
