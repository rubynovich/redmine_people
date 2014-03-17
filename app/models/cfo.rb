class Cfo < ActiveRecord::Base
  unloadable

  validates_presence_of :cfo

  has_one :person
end
