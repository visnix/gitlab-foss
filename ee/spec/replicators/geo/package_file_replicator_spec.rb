# frozen_string_literal: true

require 'spec_helper'

describe Geo::PackageFileReplicator do
  let(:model_record) { build(:package_file, :npm) }

  include_examples 'a blob replicator'

  include_examples 'secondary counters', :package_file_registry
end
