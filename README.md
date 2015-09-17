pdop_libs Cookbook
==================
Extends chef classes with our libraries and provides our definitions

Requirements
------------
- Chef 11 or higher


Libraries
------------
opsit_libs Library extends the following classes:  
    Chef::Recipe  
    Chef::Provider  
  
The following functions are now available in all of the classes above:  
    def get_settings_by_role(role, settings, includeme=true, options={})  
    def get_settings_by_recipe(recipe, settings, options={})  
    def get_settings_by_tag(tag, settings, options={})  
    def get_role_count(role, includeme=true, options={})  
    def get_nodes_by_role(role, includeme=true, options={})  
    def get_nodes_by_recipe(recipe, includeme=true, options={})  
    def get_nodes_by_tag(tag, includeme=true, options={})  
  


Recipes
-------
### default
This loads any libraries that overwrite chef provided resources.


Authors
-----------------
- Original Author: Salvatore Poliandro III <sal@keep.com>



```text
Copyright 2014 Keep.com
```