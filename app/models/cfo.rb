class Cfo < ActiveRecord::Base
  unloadable

  validates_presence_of :cfo
  validates_presence_of :cfo_slug
  validates_uniqueness_of :cfo_slug

  has_one :person

  def to_s
    (id.nil? || id == 0) ? "<#{l(:label_none)}>" : cfo_slug
  end

end
