# frozen_string_literal: true

module EE
  module API
    module Helpers
      module UsersHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :shared_runners_minutes_limit, type: Integer, desc: 'Pipeline minutes quota for this user'
            optional :extra_shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Extra pipeline minutes quota for this user'
          end

          params :optional_index_params_ee do
            optional :skip_ldap, type: Grape::API::Boolean, default: false, desc: 'Skip LDAP users'
          end
        end
      end
    end
  end
end
