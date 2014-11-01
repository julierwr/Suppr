class Dinner < ActiveRecord::Base
  belongs_to :host, :class_name => "User"

  CATEGORIES = ["American", "Chinese", "Italian", "Japanese", "Indian"]
	validates :location, :description, :title, :category, :price, :seats, :host, presence: true
	validates_numericality_of :seats, :price, :greater_than_or_equal_to =>0
	validate :not_past_date
  validates :seats, numericality: { :greater_than_or_equal_to => :seats_available}

	def not_past_date
		if self.date.past?
			errors.add(:date, 'Dinner can not be hosted in the past')
		end
	end
end
