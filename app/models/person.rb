# -*- coding: utf-8 -*-
class Person < User
  unloadable
  #self.inheritance_column = :_type_disabled
  self.inheritance_column = :_type_disabled

  belongs_to :department
  belongs_to :cfo
  belongs_to :leader, :class_name => 'Person', :foreign_key => 'leader_id'
  has_many :slaves, :foreign_key => 'leader_id', :class_name => 'Person'


  #has_to :,


  include Redmine::SafeAttributes

  def self.genders
    [[l(:label_people_male), 0], [l(:label_people_female), 1]]
  end

  def self.cities
    {l(:label_people_city_noname) => 0, l(:label_people_city_m) => 1, l(:label_people_city_spb) => 2}
  end

  after_save :update_sanitized_phones

  after_initialize :stash_old_department
  after_save :update_roles_from_new_department
  
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
    self.class.cities.key(self[:city])
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

  def sanitize_phones
    if phone.present? && @sanitized_phones_new.nil?
      arr = ""
      mobiles = ""
      unless phone_work.blank?          # work phone exist
        arr = phone_work.gsub(/[-+()\s]/, '')
        arr[0]  = "7"
        arr = "+#{arr}"

        tmp = 0
        self.class.cities.each do |key, city|
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
      @sanitized_phones_new = phone_new
      @sanitized_arr = arr
      arr
    else
      @sanitized_arr
    end
  end

  def update_sanitized_phones
    unless phone.blank?
      sanitize_phones if @sanitized_phones_new.nil?
      update_column(:phone, @sanitized_phones_new) unless @sanitized_phones_new.blank?
      update_column(:sanitized_phones, @sanitized_arr)
    end

    #unless self.phone.blank?
    #  update_column(:sanitized_phones, self.phone.gsub(/[-()\s]/, ''))
    #end
  end

  def stash_old_department
    @old_department = self.department
    # Rails.logger.error("заначено старое подразделение #{@old_department.try(:name)}".yellow)
  end

  def update_roles_from_new_department
    Rails.logger.error("update_roles_from_new_department".yellow)
    Rails.logger.error("новое подразделение: #{department.name}".yellow)
    if @old_department && @old_department != department
      Rails.logger.error("condition".yellow)
      old_internal_role = @old_department.try(:default_internal_role)
      old_external_role = @old_department.try(:default_external_role)
      new_internal_role = department.try(:default_internal_role)
      new_external_role = department.try(:default_external_role)
      for project in self.projects
        roles_in_project = self.roles_for_project(project)
        if roles_in_project.include?(old_internal_role) || roles_in_project.include?(old_external_role)
          Rails.logger.error(" #{name} добавлен в проект ##{project.id} с ролью #{project.is_external? ? old_external_role.name : old_internal_role.name }".yellow)
          member = Member.where(project_id: project.id, user_id: self.id).first
          Rails.logger.error("member: #{member.inspect}".yellow)
          Rails.logger.error("до замены: #{member.roles.map{|r| r.name}.inspect}".yellow)
          if project.is_external?
            return false unless new_external_role
            old_member_role = member.member_roles.where(role_id: old_external_role.id)
            member.roles << new_external_role if old_member_role
          else
            return false unless new_internal_role
            old_member_role = member.member_roles.where(role_id: old_external_role.id)
            member.roles << new_internal_role if old_member_role
          end
          Rails.logger.error("количество: #{old_member_role.count}")
          old_member_role.map(&:destroy)
          Rails.logger.error("удаление: #{old_member_role.all?{|mr| mr.destroyed?}}")
          Rails.logger.error("после замены: #{member.roles.map{|r| r.name}.inspect}".yellow)
        end
      end
    end 
  end
end


