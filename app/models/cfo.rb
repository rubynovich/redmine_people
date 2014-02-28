class Cfo < ActiveRecord::Base
  unloadable

  validates_presence_of :cfo

  belongs_to :person
end
