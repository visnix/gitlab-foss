# frozen_string_literal: true

module EE
  module Resolvers
    module Users
      module GroupsResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :unconditional_includes
        def unconditional_includes
          [:saml_provider, *super]
        end
      end
    end
  end
end
