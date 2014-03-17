# -*- coding: utf-8 -*-
class Person < User
  unloadable
  self.inheritance_column = :_type_disabled

  belongs_to :department
  belongs_to :cfo
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  has_many :slaves, :foreign_key => 'leader_id', :class_name => 'Person'
  #has_to :,


  include Redmine::SafeAttributes

  GENDERS = [[l(:label_people_male), 0], [l(:label_people_female), 1]]
  CITIES = {l(:label_people_city_noname) => 0, l(:label_people_city_m) => 1, l(:label_people_city_spb) =>2}

  after_save :update_sanitized_phones

  scope :in_department, lambda {|department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    if department_id.present?
      department_with_descendants_ids = Department.find(department_id).self_and_descendants.pluck(:id)
      { :conditions => {:department_id => department_with_descendants_ids, :type => "User"} }
    end
  }

  scope :not_in_department, lambda {|department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    { :conditions => ["(#{User.table_name}.department_id != ?) OR (#{User.table_name}.department_id IS NULL)", department_id] }
  }

  scope :seach_by_name, lambda {|search|

    {:conditions =>   ["(LOWER(#{Person.table_name}.firstname) LIKE ? OR
                         LOWER(#{Person.table_name}.lastname) LIKE ? OR
                         LOWER(#{Person.table_name}.middlename) LIKE ? OR
                         LOWER(#{Person.table_name}.login) LIKE ? )",
                       search.downcase + "%",
                       search.downcase + "%",
                       search.downcase + "%",
                       search.downcase + "%"
                      ]
    }
  }

  scope :search_by_phone, lambda {|search|

    strip_punctuation = search.downcase.gsub(/[-()\s—–‒]/, '')
    seven_goes_eight  = strip_punctuation.sub(/^\+7/, '8')
    eight_goes_seven  = strip_punctuation.sub(/^8/, '+7')
    # phone_search_string = phone_search_string.gsub(/^8/, '+7') if phone_search_string.size == 11

    {:conditions => ["( LOWER(#{Person.table_name}.sanitized_phones) LIKE ? OR
                        LOWER(#{Person.table_name}.sanitized_phones) LIKE ? OR
                        LOWER(#{Person.table_name}.sanitized_phones) LIKE ?)",
                     "%" + strip_punctuation + "%", # search anywhere by substring without punctuation
                     "%" + seven_goes_eight + "%", # search from beginning with +7/8 conversion - +7 changes to 8
                     "%" + eight_goes_seven + "%"  # search from beginning with +7/8 conversion - 8 changes to +7
                    ]
    }

  }

  scope :search_by_city, lambda {|search|
    {:conditions =>   ["( LOWER(#{Person.table_name}.city) = ? )", search ] } 
  }

  scope :search_by_mail, lambda {|search|
    {:conditions =>   ["( LOWER(#{Person.table_name}.mail) LIKE ? )", "%" + search.downcase + "%" ] }
  }

  scope :search_by_job_title, lambda {|search|
    {:conditions =>   ["( LOWER(#{Person.table_name}.job_title) LIKE ? )", "%" + search.downcase + "%" ] }
  }

  validates_uniqueness_of :firstname, :scope => [:lastname, :middlename]
  validate :phones_correct
  #validates :mail, :email =>  {:strict_mode => true}
  validates_format_of :mail, :with => /^[0-9a-zA-Z][0-9a-zA-Z\-\_]*(\.[0-9a-zA-Z\-\_]*[0-9a-zA-Z]+)*@[0-9a-zA-Z][0-9a-zA-Z\-\_]*(\.[0-9a-zA-Z\-\_]*[0-9a-zA-Z]+)*\.[a-zA-Z]{2,}$/i
  
  

  safe_attributes 'phone',
                  'address',
                  'skype',
                  'birthday',
                  'job_title',
                  'company',
                  'middlename',
                  'gender',
                  'twitter',
                  'facebook',
                  'linkedin',
                  'department_id',
                  'background',
                  'appearance_date',
                  'city',
                  'identity_url',
                  'cfo_id',
                  'leader_id'

  def phones
    unless self.phone.blank?
      self.phone.sub!(/[^,]\s+\+/, ", +") 
    end
    @phones || self.phone ? self.phone.split(/(?:[,;]|доб\.*)\s*/)-[""] : []
  end

  def phone_extension
    if phones.index { |x| x.length > 0 and x.length < 6 } 
      phones[phones.index { |x| x.length > 0 and x.length < 6 }] 
    else
      []
    end
  end

  def phone_work
    phones.each do |value| 
      if value.index(/\+*[78] *\(*(495|499|812)/)  
        return value 
      end
    end
    return []
  end

  def phone_mobile
    phones - [phone_work] - [phone_extension] - [" "]
  end

  def phones_correct
    if phone_mobile.present?
      phone_mobile.each do |phone|
        unless phone.index(/^\s*\+7\s{1}\([0-9]{3}\)\s{1}[0-9]{3}\-[0-9]{2}\-[0-9]{2}\s*$/)
          errors.add(:phone, :label_people_mobile_errors)
          break
        end
      end
    end
  end

  def name(formatter = nil)
    if middlename.present?
      [super(formatter),"#{middlename}"].join(" ")
    else
      super(formatter)
    end
  end


  def city
    CITIES.key(self[:city]) 
  end

  def city=(new_city)
    self[:city] = new_city
  end

  def type
    'User'
  end

  def email
    self.mail
  end

  def project
    nil
  end

  def next_birthday
    return if birthday.blank?
    year = Date.today.year
    mmdd = birthday.strftime('%m%d')
    year += 1 if mmdd < Date.today.strftime('%m%d')
    mmdd = '0301' if mmdd == '0229' && !Date.parse("#{year}0101").leap?
    return Date.parse("#{year}#{mmdd}")
  end

  def self.next_birthdays(limit = 10)
    Person.where("users.birthday IS NOT NULL").sort_by(&:next_birthday).first(limit)
  end

  def age
    return nil if birthday.blank?
    now = Time.now
    age = now.year - birthday.year - (birthday.to_time.change(:year => now.year) > now ? 1 : 0)
  end

  def editable_by?(usr, prj=nil)
    true
    # usr && (usr.allowed_to?(:edit_people, prj) || (self.author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def visible?(usr=nil)
    true
  end

  def attachments_visible?(user=User.current)
    true
  end

  def update_sanitized_phones
    unless phone.blank?
      #puts "---------------------------------" 
      #puts "all:    " + p.phone
      arr = ""
      mobiles = ""
      unless phone_work.blank?          # work phone exist
          arr = phone_work.gsub(/[-+()\s]/, '')
          arr[0]  = "8"

          tmp = 0
          Person::CITIES.each do |key, city| 
              cities = Setting.plugin_redmine_people[:"sett_city_default_#{city}"].split(/,\s*/)
              cities.each { |city_one| tmp = 1 if arr == city_one }
          end
          if tmp == 0
              #puts "arr:    " + arr + " " + Setting.plugin_redmine_people[:"sett_city_default_0"]+ " " + Setting.plugin_redmine_people[:"sett_city_default_1"]+ " " + Setting.plugin_redmine_people[:"sett_city_default_2"]
              arr = ""
              mobiles = phone_work.dup
          end
      end
      if !phone_extension.blank? && arr.size == 0 # work phone doesn't exist, but extension does   
          #puts "city = " + p[:city].to_s
          arr = Setting.plugin_redmine_people[:"sett_city_default_#{self[:city]}"].split(/,\s*/) unless Setting.plugin_redmine_people[:"sett_city_default_#{self[:city]}"].blank?
          arr = arr[0]

          # add work phone into p.phone
          phone_new = "+7 ("
          shift = 1         
          phone_new << arr.slice(shift,3)    # city_code
          phone_new << ") "
          phone_new << arr.slice(shift+3,3)   # XXX
          phone_new << "-"
          phone_new << arr.slice(shift+6,2)     # XX
          phone_new << "-"
          phone_new << arr.slice(shift+8,2)    # XX
          phone_new << ", " + phone.dup
          #puts "p ==== " + phone_new
      end
      

      unless phone_extension.blank? 
          arr << "," if arr.size > 0
          arr << phone_extension.dup
      end            

      phone_mobile.each do |mobiles|
          unless mobiles.blank?                    
              phone_copy = mobiles.dup
              phone_copy.gsub!(/[-()\s]/, '')
              arr << ", " if arr.size > 0
              arr << phone_copy                    
          end
      end 

      unless mobiles.blank?
          phone_copy = mobiles.dup
          phone_copy.gsub!(/[-()\s]/, '')
          arr << ", " if arr.size > 0
          arr << phone_copy                     
      end 


      update_column(:phone, phone_new) unless phone_new.blank?
      update_column(:sanitized_phones, arr)
      #puts "end:    id=" + p.id.to_s + "  phone=" + arr
      #puts
    end

    #unless self.phone.blank?
    #  update_column(:sanitized_phones, self.phone.gsub(/[-()\s]/, ''))
    #end
  end

end
