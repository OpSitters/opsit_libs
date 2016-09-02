# Author:: Salvatore Poliandro III (sal@opsitters.com)
# Cookbook Name:: opsit_libs
# Library:: search
#
# Copyright 2015, OpSitters
# Copyright 2012-2013, Rackspace US, Inc. (osops-utils cookbook)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#



require "chef/search/query"

module OPSITTERS

  # This takes an active node hash and returns a data array making it safe to 
  # edit and manipulate without affecting the node
   def node_safe_deref(hash, path, delim = ".")
    current = hash

    opsit_log("searching for #{path} in #{hash} with delimiter #{delim}")
    path_ary = path.split(delim)
    path_ary.each do |k|
      if current and current.has_key?(k)
        current = current[k]
      elsif current and current.respond_to? k
        current = current.send(k)
      else
        current = nil
      end
    end

    current
  end



  # Get node hash(es) by recipe or role.
#    options = {
#      :search_string => "" # recipe or role name
#      :order => :role | :recipe # which has precedence
#      :one_or_all => :one | :all # return single result or a list of results
#      :include_me => true | false # include self in results
#      :safe_deref => nil | !nil, # if nil, return node(s), else return hash
#      :current_node => node object # will be set to current node if not passed
#      :multi_environment => nil | !nil #if nil, search current env only
#    }
  def opsit_search(options = {})

    search_string = options[:search_string]
    order = options[:order]
    one_or_all = options[:one_or_all].nil? ? :one : options[:one_or_all]
    include_me = options[:include_me].nil? ? :true : options[:include_me]
    safe_deref = options[:safe_deref].nil? ? nil : options[:safe_deref]
    current_node = options[:current_node].nil? ? nil : options[:current_node]
    multi_environment = options[:multi_environment].nil? ? nil : options[:multi_environment]
    location = options[:location].nil? ? nil : options[:location]
    specific_environment = options[:specific_environment].nil? ? nil : options[:specific_environment]

    opsit_log("search_string:#{search_string}, one_or_all:#{one_or_all},"\
      + "include_me:#{include_me}, order:#{order}, safe_deref:#{safe_deref},"\
      + "multi_environment:#{multi_environment}, location:#{location},"\
      + "specific_environment:#{specific_environment}")
    results = {
      :recipe => [],
      :role => [],
      :tag => []
    }

    current_node ||= node

    for query_type in order
      if include_me and current_node["#{query_type}s"].include? search_string
        opsit_log("node #{current_node} contains #{query_type} #{search_string}, so adding node to results")
        results[query_type] << current_node
        break if one_or_all == :one # skip expensive searches if unnecessary
      end

      search_string.gsub!(/::/, "\\:\\:")

      if not multi_environment
        if not specific_environment
          query = "#{query_type}s:#{search_string} AND chef_environment:#{current_node.chef_environment}"
        else
          query = "#{query_type}s:#{search_string} AND chef_environment:#{specific_environment}"
        end
      else
        query = "#{query_type}s:#{search_string}"
      end

      if location and location != "all"
        query << " AND OPSITTERS_location:#{location}"
      end

      opsit_log("query: #{query}")
      result, _, _ = Chef::Search::Query.new.search(:node, query)
      results[query_type].push(*result)
      break if one_or_all == :one and results.values.map(&:length).reduce(:+).nonzero?
    end #end for

    #combine results into prioritised list
    return_list = order.map { |search_type| results[search_type] }.reduce(:+)

    #remove duplicates
    return_list.uniq!(&:name)

    #remove self if returned by search but include_me is false
    return_list.delete_if { |e| e.name == current_node.name }  if not include_me

    if not safe_deref.nil?
      # result should be dereferenced, do that then remove nils.
      opsit_log("applying deref #{safe_deref}")
      return_list.map! { |nodeish| node_safe_deref(nodeish, safe_deref) }
      return_list.delete_if { |item| item.nil? }
    end

    opsit_log("return_list: #{return_list}")

    if one_or_all == :one
      #return first item
      return_list.first
    else
      #return list (even if it only contains one item)
      return_list
    end
  end #end function

  # Get a specific node hash from another node by role
  #
  # In the event of a search with multiple results,
  # it returns the first match
  #
  # In the event of a search with a no matches, if the role
  # is held on the running node, then the current node hash
  # values will be returned
  #
  # If includeme=false, the current node hash is removed from the results
  # before the results are evaluated and returned
  def get_settings_by_role(role, settings, includeme=true, options={})
    options = {
      :search_string => role,
      :include_me => include_me,
      :order => [:role],
      :safe_deref => settings,
      :current_node => nil,
      :one_or_all => :one
    }.merge(options)
    opsit_search(options)
  end

  # Get a specific node hash from another node by recipe
  #
  # In the event of a search with multiple results,
  # it returns the first match
  #
  # In the event of a search with a no matches, if the role
  # is held on the running node, then the current node hash
  # values will be returned
  #
  def get_settings_by_recipe(recipe, settings, options={})
    options = {
      :search_string => recipe,
      :include_me => true,
      :order => [:recipe],
      :safe_deref => settings,
      :current_node => nil,
      :one_or_all => :one
    }.merge(options)
    opsit_search(options)
  end

  # Get a specific node hash from another node by tag
  #
  # In the event of a search with multiple results,
  # it returns the first match
  #
  # In the event of a search with a no matches, if the tag
  # is held on the running node, then the current node hash
  # values will be returned
  def get_settings_by_tag(tag, settings, options={})
    options = {
      :search_string => tag,
      :include_me => true,
      :order => [:tag],
      :safe_deref => settings,
      :current_node => nil,
      :one_or_all => :one
    }.merge(options)
    opsit_search(options)
  end

  # search for a role and return how many there are in the environment.
  #
  # If includeme=false, the current node is removed from the search result
  # before the results are evaluated and returned
  def get_role_count(role, includeme=true, options={})
    options = {
      :search_string => role,
      :include_me => includeme,
      :order => [:role],
      :safe_deref => nil,
      :current_node => nil,
      :one_or_all => :all
    }.merge(options)
    opsit_search(options).length
  end

  # search for a role and return the node hashes with that role.
  #
  # If includeme=false, the current node is removed from the search result
  # before the results are evaluated and returned
  def get_nodes_by_role(role, includeme=true, options={})
    options = {
      :search_string => role,
      :include_me => includeme,
      :order => [:role],
      :safe_deref => nil,
      :current_node => nil,
      :one_or_all => :all
    }.merge(options)
    opsit_search(options)
  end

  # search for a recipe and return the node hashes with that recipe.
  #
  # If includeme=false, the current node is removed from the search result
  # before the results are evaluated and returned
  def get_nodes_by_recipe(recipe, includeme=true, options={})
    options = {
      :search_string => recipe,
      :include_me => includeme,
      :order => [:recipe],
      :safe_deref => nil,
      :current_node => nil,
      :one_or_all => :all
    }.merge(options)
    opsit_search(options)
  end

  # search for a tag and return the node hashes with that role.
  #
  # If includeme=false, the current node is removed from the search result
  # before the results are evaluated and returned
  def get_nodes_by_tag(tag, includeme=true, options={})
    options = {
      :search_string => tag,
      :include_me => includeme,
      :order => [:tag],
      :safe_deref => nil,
      :current_node => nil,
      :one_or_all => :all
    }.merge(options)
    opsit_search(options)
  end

end #end module

class Chef::Recipe
  include OPSITTERS
end

class Chef::Provider
  include OPSITTERS
end
