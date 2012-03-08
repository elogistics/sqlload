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

module DB
  require 'pg'
  ##
  # Yields a database connection configured with the supplied options.
  # This method will attempt to close the connection once the block terminates.
  def get_db_connection(options)
    dbname = options[:dbname]
    unless dbname
      abort  "You must specify a database name"
    end
    user = options.fetch(:user, dbname)
    password = options[:password]
    port = options.fetch(:port, 5432)
    begin
      db_connection = PG.connect(:host => 'localhost', :port => port, :dbname => dbname, :user => user, :password => password)
      yield db_connection
    ensure
      db_connection.finish unless db_connection.nil?
    end
  end
end


module DBConfig
  ##
  # Generates a configuration hash from a JSON file
  #
  # [path] the path to the dataset to load a config for 
  def load_config(path)
    require 'json'

    config = JSON.parse(File.read(self.get_config_path(path)), :symbolize_names => true)
  end

  def get_config_path(dataset_path)
    File.join(dataset_path, 'config.json')
  end
end

## 
# A collection of data that can be inserted together into a database
class DataSet
  include DBConfig, DB
  attr_accessor :ups, :downs, :config, :directory

  ##
  # Creates a dataset using the SQL and the configuration contained
  # in directory. The supplied user configuration overrides
  # the configuration contained in the directory
  def initialize(directory, user_config = {})
    @ups = []
    @downs = []
    @directory = directory
    populate() 
    @config = load_config(directory).merge(user_config)
    if insufficient(config)
      raise ArgumentError, 'No database name'
    end
  end
  
  ##
  # If there are reset scripts available,
  # executes them before executing once again the regular scripts
  def reset
    if @downs.empty?
       raise ArgumentError, 'There are no reset scripts to run'
     end
    load
    delete
   end

   ##
   # Executes the SQL scripts associated with the dataset.
   def load
     get_db_connection(@config) do |db_connection|
       @ups.each do |s|
         result = db_connection.exec(s)
         puts result.cmd_status
       end
     end
   end
   
   ##
   # Executes the SQL scripts marked as reset scripts
   def delete
     get_db_connection(@config) do |db_connection|
     @downs.each do |s|
         result = db_connection.exec(s)
         puts result.cmd_status
       end
     end
   end

   def to_s
     File.basename(@directory)
   end

  private
   
   # Fills the list of statements to execute from the information
   # found by inspecting the directory contents
   def populate()
     require 'find'
     upfiles = []
     downfiles = []
     Find.find(@directory) do |path|
       if is_downs(path)
           downfiles.push(path)
       elsif is_ups(path)
         upfiles.push(path)
       end
    end
    upfiles.sort! do |x, y|
      File.basename(x) <=> File.basename(y)
    end
    
    upfiles.each do |f|
      @ups <<  File.read(f)
    end
    
    downfiles.each do |f|
       @downs << File.read(f)
     end
   end

  # Returns true if the configuration does not contain enough information
  # to connect to a database 
  def insufficient(config)
    return config[:dbname].nil? 
  end

  def is_ups(path)
    return File.extname(path) == '.sql' && File.basename(path) != 'reset.sql'
  end

  def is_downs(path)
    return File.basename(path) == 'reset.sql'
  end
end
