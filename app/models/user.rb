class User < ApplicationRecord
  has_many :clients, dependent: :destroy
  has_many :calendars, dependent: :destroy
  has_many :notes, dependent: :destroy
end
