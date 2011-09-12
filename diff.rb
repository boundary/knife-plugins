#
## Author:: Joe Williams (j@boundary.com)
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require File.expand_path('../lib/boundary_knife_plugins.rb', __FILE__)

require 'chef/knife'
require 'digest/md5'

module BoundaryKnifePlugins
  class DiffCookbooks < Chef::Knife
    include Common
    
    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife diff cookbooks"
    
    def run
      self.config = Chef::Config.merge!(config)
      
      remote_cookbooks = build_sorted_remote_cookbook_list(rest)
      
      local_cookbooks = build_sorted_local_cookbook_list
      
      local_only = diff_lists(local_cookbooks, remote_cookbooks)
      ui.info("Local orphan cookbooks:")
      ui.info(local_only)
      
      remote_only = diff_lists(remote_cookbooks, local_cookbooks)
      ui.info("\nRemote orphan cookbooks:")
      ui.info(remote_only)
      
    end
  end
  
  class DiffCookbook < Chef::Knife
    include Common

    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife diff cookbook COOKBOOK [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all cookbooks (list provided by local repo), rather than just a single cookbook"
        
    def run
      self.config = Chef::Config.merge!(config)
      
      if config[:all]
        remote_cookbooks = build_sorted_local_cookbook_list
        
        remote_cookbooks.each do |cookbook|
          cookbook_compare(ui, rest, cookbook)
        end
        
      else
        unless name_args.size == 1
          ui.error("Please specify a cookbook!")
          show_usage
          exit 1
        end

        cookbook_compare(ui, rest, name_args.first)
      end
    end
  end
  
  class DiffDatabags < Chef::Knife
    include Common

    deps do
      require 'chef/data_bag'
    end
    
    banner "knife diff databags"
    
    def run
      path = "#{Chef::Config[:cookbook_path]}/../data_bags"
      
      local_dbags = get_sorted_local_databags(path)
      
      remote_dbags = Chef::DataBag.list.keys.sort
      
      ui.info("Local orphan databags:")
      ui.info(local_dbags.sort - remote_dbags)
      
      ui.info("\nRemote orphan databags:")
      ui.info(remote_dbags - local_dbags.sort)
    end
    
  end
  
  class DiffDatabagItems < Chef::Knife
    include Common

    deps do
      require 'chef/data_bag'
    end
    
    banner "knife diff databag items DATABAG [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all data bags (list provided by local repo), rather than just a single cookbook"
    
    def run
      path = "#{Chef::Config[:cookbook_path]}/../data_bags"
            
      if config[:all]
        local_dbags = get_sorted_local_databags(path)
            
        local_dbags.each do |databag|
          compare_databag_item_lists(ui, path, databag)
        end        
      else
        compare_databag_item_lists(ui, path, name_args.first)
      end
    end
    
  end
  
  class DiffDatabag < Chef::Knife
    include Common

    deps do
      require 'chef/data_bag'
    end
    
    banner "knife diff databag DATABAG [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all data bags (list provided by local repo), rather than just a single cookbook"
    
    def run
      path = "#{Chef::Config[:cookbook_path]}/../data_bags"
      
      if config[:all]
        remote_dbags = Chef::DataBag.list.keys
        
        remote_dbags.each do |dbag|
          compare_databag_items(ui, path, dbag)
        end
        
      else
        compare_databag_items(ui, path, name_args.first)
      end
    end
    
  end

  
end