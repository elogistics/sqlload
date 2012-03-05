#!/usr/bin/env ruby

#   Copyright 2012 Ludovico Fischer
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'lib/dataset'


module Tasks
  def self.get_datasets(directory = 'SQL', user_config)
    datasets = []
    datasets << DataSet.new(directory, user_config)
    datasets
  end

  def self.list_available_datasets(user_options)
    self.get_datasets(user_options).each do |d|
      puts d.ups + d.downs
    end
  end
end

module User
  def self.get_commandline_options(command_string)
    require 'optparse'

    options = {}

    optparse = OptionParser.new do |opts|
      opts.on('-U', '--user USERNAME', 'Specify username') do |user|
        options[:user] = user
      end

      opts.on('-W', '--password PASSWORD', 'Specify password') do |password|
        options[:password] = password
      end

      opts.on('-d', '--database DBNAME', 'Specify database name') do |dbname|
        options[:dbname] = dbname
      end

      opts.on('-p', '--port PORT', 'Specify port') do |port|
        options[:port] = port
      end

      opts.on('-h', '--help', 'Print usage') do
        puts opts
        exit
      end
    end

    optparse.parse!(command_string)
    options

  end
end

user_options = User.get_commandline_options(ARGV)
dataset_name = ARGV[1]

case ARGV[0]
when 'list'
  Tasks.list_available_datasets(user_options)
when 'load'
  if dataset_name.nil? then abort 'You must specify a dataset to load' end
  dataset = Dataset.new(dataset_name, user_options)
  dataset.load
when 'reset'
  if dataset.nil? then abort 'You must specify a dataset to reset' end
  dataset = Dataset.new(dataset_name, user_options)
  dataset.reset
else abort 'You must specify one of list, load or reset.'
end

