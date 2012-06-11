begin
  require 'rackspace-monitoring'
rescue LoadError
  Chef::Log.warn("Missing gem 'rackspace-monitoring'")
end

module Rackspace
  module CloudMonitoring

    def cm
      begin
        dbag = data_bag_item("cloud_monitoring", "main")
      rescue
        dbag = {:rackspace_api_key => nil, :rackspace_username => nil }
      end
      apikey = new_resource.rackspace_api_key || dbag[:rackspace_api_key]
      username = new_resource.rackspace_username || dbag[:rackspace_username]
      @@cm ||= Fog::Monitoring::Rackspace.new(:rackspace_api_key => apikey, :rackspace_username => username)
      @@view ||= Hash[@@cm.entities.overview.map {|x| [x.identity, x]}]
      @@cm
    end

    def clear
      @@view = nil
    end

    def view
      cm
      @@view
    end

    def get_entity_by_id(id)
      view[id]
    end

    def get_entity_by_name(name)
      possible = view.select {|key, value| value.label === name}
      if !possible.empty? then
        possible.values.first
      else
        nil
      end
    end

    def get_type(entity_id, type)
      if type == 'checks' then
        view[entity_id].checks
      elsif type == 'alarms' then
        view[entity_id].alarms
      else
        raise Exception, "type #{type} not found."
      end
    end

    def get_child_by_id(entity_id, id, type)
      objs = get_type entity_id, type
      obj = objs.select { |x| x.identity === id }
      if !obj.empty? then
        obj.first
      else
        nil
      end

    end

    def get_child_by_name(entity_id, name, type)
      objs = get_type entity_id, type
      obj = objs.select {|x| x.label === name}
      if !obj.empty? then
        obj.first
      else
        nil
      end
    end

    def get_check_by_id(entity_id, id)
      get_child_by_id entity_id, id, 'checks'
    end

    def get_alarm_by_id(entity_id, id)
      get_child_by_id entity_id, id, 'alarms'
    end

    def get_check_by_name(entity_id, name)
      get_child_by_name entity_id, name, 'checks'
    end

    def get_alarm_by_name(entity_id, name)
      get_child_by_name entity_id, name, 'alarms'
    end
  end
end
