# -*- coding: utf-8 -*-
class SkynetObserver < ActiveRecord::Base
  unloadable
  belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  validates_uniqueness_of :user_id
end