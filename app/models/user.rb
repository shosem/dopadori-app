class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :registerable, :validatable
  validates :name, presence: true, length: { maximum: 10 }

  has_many :alternative_actions, dependent: :destroy
end
