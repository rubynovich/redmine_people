# -*- coding: utf-8 -*-
class Person < User
  unloadable
  self.inheritance_column = :_type_disabled

  belongs_to :department
  has_one :cfo

  include Redmine::SafeAttributes

  GENDERS = [[l(:label_people_male), 0], [l(:label_people_female), 1]]
  CITIES = {l(:label_people_city_noname) => 0, l(:label_people_city_m) => 1, l(:label_people_city_spb) =>2}

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

  scope :search_by_mail, lambda {|search|
    {:conditions =>   ["( LOWER(#{Person.table_name}.mail) LIKE ? )", "%" + search.downcase + "%" ] }
  }

  scope :search_by_job_title, lambda {|search|
    {:conditions =>   ["( LOWER(#{Person.table_name}.job_title) LIKE ? )", "%" + search.downcase + "%" ] }
  }

  scope :search_by_city, lambda {|search|
    {:conditions =>   ["( LOWER(#{Person.table_name}.city) = ? )", search ] } 
  }

  validates_uniqueness_of :firstname, :scope => [:lastname, :middlename]

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
                  'city'

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
    unless self.phone.blank?
      update_column(:sanitized_phones, self.phone.gsub(/[-()\s]/, ''))
    end
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


