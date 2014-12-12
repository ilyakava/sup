Sup::Application.routes.draw do
  root to: 'members#graph'

  resources :members do
    collection do
      get 'graph'
    end
  end

  resources :meetings, only: [:edit, :update]
  resources :feedbacks, only: [:new, :create]
end
