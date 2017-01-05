#!/usr/bin/env ruby
require_relative '../boot.rb'

remediate do
  each_druid do
    publish_metadata_remotely
  end
end
