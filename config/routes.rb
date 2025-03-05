# frozen_string_literal: true

Rails.application.routes.draw do
  post '/graphql', to: 'graphql#execute'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }, skip: %i[confirmations passwords]

  namespace :api do
    resources :trades, only: %i[index create]
  end
end
