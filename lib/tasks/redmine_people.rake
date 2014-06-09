# encoding: UTF-8
namespace :redmine do
  namespace :plugins do


    desc 'Export orgstructure people'
    task :export_orgstructure => :environment do
      Person.active.each do |person|
        
      end
    end


    desc 'Update null cfo'
    task :update_null_cfo => :environment do
      Person.where(cfo_id: nil).update_all(:cfo_id => 0)
    end

    desc 'Imoprt CFO from CSV.'
    task :import_cfo_id => :environment do
      require 'smarter_csv'
      if File.exists?("#{Rails.root}/tmp/cfos.csv")
        #csv_text = File.read("#{Rails.root}/tmp/cfos.csv")
        #csv = CSV.parse(csv_text, :headers => true)
        #users_not_found = []
        SmarterCSV.process("#{Rails.root}/tmp/cfos.csv", {:col_sep=>';'}).each do |row|
          #row = text_row.to_hash
          #raise row.inspect
          if person = Person.where(firstname: row[:firstname], lastname: row[:lastname], middlename: row[:middlename]).first || Person.where(firstname: row[:firstname], lastname: row[:lastname]).first
            unless row[:cfo_id].to_i == 0
              person.update_column(:cfo_id, row[:cfo_id])
            else
              puts row.inspect.green
            end
          else
            #users_not_found += row
            puts row.inspect.red
          end
        end
        #puts users_not_found.inspect
      end
    end


    desc 'Copies city from address to city in redmine_people.'
    task :people_update_city => :environment do
        Person.all.each do |p|
            if p.address && p.address.include?("Москва")                
                p.update_column(:city, 1)
            elsif p.address && p.address.include?("Санкт")
                p.update_column(:city, 2)
            else
                p.update_column(:city, 0)
                puts "0"
            end
        end
    end
    desc 'Separate work phone with template +7 (XXX) XXX-XX-XX in redmine_people.'
    task :people_update_phones => :environment do
        Person.all.each do |p|
            unless p.phone.blank?
            arr = [p.phone_work] + p.phone_mobile
            puts "---------------------------------" 
            puts "all:    " + p.phone
            arr.each do |phone|
                #puts "---------------------------------"
                unless phone.blank?
                    unless (p.phone_extension.blank?)
                        puts "phone:  _" + phone + "_, ext=_" + p.phone_extension + "_"
                    else
                        puts "phone:  _" + phone + "_"
                    end
                    phone_copy = phone.dup
                    phone_new = "+7 ("
                    phone_copy.gsub!(/[-()\s]/, '')
                    if phone_copy.include?("+7")
                        shift = 2 
                    elsif phone_copy[0] == "8"
                        shift = 1
                    else
                        shift = 0
                    end                    
                    phone_new << phone_copy.slice(shift,3)    # city_code
                    phone_new << ") "
                    phone_new << phone_copy.slice(shift+3,3)   # XXX
                    phone_new << "-"
                    phone_new << phone_copy.slice(shift+6,2)     # XX
                    phone_new << "-"
                    phone_new << phone_copy.slice(shift+8,2)    # XX
                    #puts phone_copy
                    phone_copy = p.phone.dup
                    phone_copy.sub!(phone, phone_new) 
                    p.update_column(:phone, phone_copy)
                end
            end           
            puts "end:    id=" + p.id.to_s + "  phone=" + p.phone
            puts
            end                
           
        end
    end
    desc 'Update phones format in redmine_people.'
    task :people_concat_phones => :environment do
        Person.all.each do |p|
            unless p.phone.blank?
                puts "---------------------------------" 
                puts "all:    " + p.phone
                arr = ""
                mobiles = ""
                unless p.phone_work.blank?          # work phone exist
                    arr = p.phone_work.gsub(/[-+()\s]/, '')
                    arr[0]  = "8"

                    tmp = 0
                    Person.cities.each do |key, city|
                        cities = Setting.plugin_redmine_people[:"sett_city_default_#{city}"].split(/,\s*/)
                        cities.each { |city_one| tmp = 1 if arr == city_one }
                    end
                    if tmp == 0
                        puts "arr:    " + arr + " " + Setting.plugin_redmine_people[:"sett_city_default_0"]+ " " + Setting.plugin_redmine_people[:"sett_city_default_1"]+ " " + Setting.plugin_redmine_people[:"sett_city_default_2"]
                        arr = ""
                        mobiles = p.phone_work.dup
                    end
                end
                if !p.phone_extension.blank? && arr.size == 0 # work phone doesn't exist, but extension does   
                    puts "city = " + p[:city].to_s
                    arr = Setting.plugin_redmine_people[:"sett_city_default_#{p[:city]}"].split(/,\s*/) unless Setting.plugin_redmine_people[:"sett_city_default_#{p[:city]}"].blank?
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
                    phone_new << ", " + p.phone.dup
                    puts "p ==== " + phone_new                    
                end
                

                unless p.phone_extension.blank? 
                    arr << "," if arr.size > 0
                    arr << p.phone_extension.dup
                end            

                p.phone_mobile.each do |phone|
                    #puts "---------------------------------"
                    unless phone.blank?                    
                        phone_copy = phone.dup
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

                p.update_column(:phone, phone_new) unless phone_new.blank?
                p.update_column(:sanitized_phones, arr)         
                puts "end:    id=" + p.id.to_s + "  phone=" + arr
                puts
            end                
           
        end
    end

  end
end