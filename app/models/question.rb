# A specificaton for a piece of info that the survey designer wants to collect.

class Question < ActiveRecord::Base
  belongs_to :survey
  attr_accessible :content, :mandatory, :max_length, :image, :type, :survey_id, :order_number
  validates_presence_of :content
  has_many :answers, :dependent => :destroy
  has_many :options, :dependent => :destroy
  has_attached_file :image, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  accepts_nested_attributes_for :options
  validates_uniqueness_of :order_number, :scope => :survey_id
  validates_numericality_of :max_length, :only => :integer, :greater_than => 0, :allow_nil => true

  default_scope :order => 'order_number'

  def image_url
    return image.url(:thumb) if image.exists?
    nil
  end
end