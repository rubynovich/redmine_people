namespace :redmine do
  namespace :plugins do
    desc 'Copies city from address to city in redmine_people.'
    task :people_update_city => :environment do
        Person.all.each do |p|
            if p.address && p.address.include?("Москва")                
                p.update_attribute(:city, 1)
            elsif p.address && p.address.include?("Санкт")
                p.update_attribute(:city, 2)
            else
                p.update_attribute(:city, 0)
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
                    p.update_attribute(:phone, phone_copy)
                end
            end           
            puts "end:    id=" + p.id.to_s + "  phone=" + p.phone
            puts
            end                
           
        end
    end
  end
end