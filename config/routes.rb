# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :people do
    collection do
      get :bulk_edit, :context_menu, :edit_mails, :preview_email, :avatar
      post :bulk_edit, :bulk_update, :send_mails
      delete :bulk_destroy
      #get :adding_mobile_phone
    end
end
 
resources :departments do
  member do
    get  :autocomplete_for_person
    post :add_people
    delete :remove_person
  end
end

resources :people_settings do
  collection do
    get  :autocomplete_for_user
    post :skynet
    delete :destroy_observer
  end
end
# match "people_settings/:action" => "people_settings"

resources :cfos
