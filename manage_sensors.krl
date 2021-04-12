ruleset manage_sensors {
    meta {
      use module io.picolabs.wrangler alias wrangler
      
      shares get_sensors, already_contains, get_all_temperatures
    }
  
    global {
      default_temp_threshold = 100
  
      create_pico_name = function () {
        <<Sensor #{wrangler:children().length() + 1}>>
      }
  
      already_contains = function (name) {
        ent:sensors.keys().any(function(v) {
          v == name
        })
      }
  
      get_sensors = function () {
        ent:sensors
      }
  
      get_all_temperatures = function () {
        get_sensors().values().map(function (eci) {
          wrangler:picoQuery(eci, "store.temperature", "temperatures")
        })
      }
    }
  
    rule init {
      select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid
      
      always {
        ent:sensors := {}
      }
    }
  
    rule trigger_new_sensor_creation {
      select when sensor new_sensor
  
      always {
        raise wrangler event "new_child_request"
          attributes 
            {
              "name": create_pico_name()
            }
        if not already_contains(create_pico_name()).klog("already in sensors?")
      }
    }
  
    rule on_child_created {
      select when wrangler new_child_created
  
      pre {
        eci = event:attrs{"eci"}
        name = event:attrs{"name"}
      }
  
      fired {
        raise sensor event "temperature_store_child"
          attributes event:attrs
      }
    }
  
    rule on_child_initialized {
      select when wrangler child_initialized
      
      pre {
        name = event:attrs{"name"}
        eci = ent:sensors{event:attrs{"name"}}
      }
  
      event:send({
        "eci": eci,
        "eid": "initialize-pico",
        "domain": "sensor", "type": "profile_updated",
        "attrs": {
          "name": name,
          "location": "default",
          "temperature_threshold": default_temp_threshold,
          "recipient_phone_number": "+13853332010"
        }
      })
    }
  
    rule install_temperature_store_child {
      select when sensor temperature_store_child
      
      pre {
        eci = event:attrs{"eci"}
        name = event:attrs{"name"}
      }
      
      event:send(
        {
          "eci": eci,
          "eid": "install-ruleset",
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": meta:rulesetURI,
            "rid": "temperature_store",
            "config": {}
          }
        }
      )
  
      always {
        raise sensor event "twilio_child"
          attributes event:attrs
      }
    }
  
    rule install_twilio_in_child {
      select when sensor twilio_child
  
      pre {
        eci = event:attrs{"eci"}
        name = event:attrs{"name"}
      }
  
      event:send(
        {
          "eci": eci,
          "eid": "install-ruleset",
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": meta:rulesetURI,
            "rid": "twilio_ruleset",
            "config": {}
          }
        }
      )
  
      always {
        raise sensor event "wovyn_base_child"
          attributes event:attrs
      }
    }
  
    rule install_wovyn_base_in_child {
      select when sensor wovyn_base_child
  
      pre {
        eci = event:attrs{"eci"}
        name = event:attrs{"name"}
      }
  
      event:send(
        {
          "eci": eci,
          "eid": "install-ruleset",
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": meta:rulesetURI,
            "rid": "wovyn_base",
            "config": {	"account_sid": "ACae3b6c21c8c2e8ecbc75e42c1091a8e9", "authtoken": "4b5606d58730a7c754a6b81771050918"}
          }
        }
      )
  
      always {
        raise sensor event "sensor_profile_child"
          attributes event:attrs
      }
    }
  
    rule install_sensor_profile_in_child {
      select when sensor sensor_profile_child
  
      pre {
        eci = event:attrs{"eci"}
        name = event:attrs{"name"}
      }
  
      event:send(
        {
          "eci": eci,
          "eid": "install-ruleset",
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": meta:rulesetURI,
            "rid": "sensor_profile",
            "config": {}
          }
        }
      )
  
      always {
        raise sensor event "emitter_child"
          attributes event:attrs
      }
    }
  
    rule install_emiter_in_child {
      select when sensor emitter_child
  
      pre {
        eci = event:attrs{"eci"}
        name = event:attrs{"name"}
      }
  
      event:send(
        {
          "eci": eci,
          "eid": "install-ruleset",
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": meta:rulesetURI,
            "rid": "io.picolabs.wovyn.emitter",
            "config": {}
          }
        }
      )
  
      always {
        raise sensor event "store_new_sensor"
          attributes event:attrs
      }
    }
  
    rule store_new_sensor {
      select when sensor store_new_sensor
  
      pre {
        name = event:attrs{"name"}
        eci = event:attrs{"eci"}
      }
  
      always {
        ent:sensors{name} := eci
      }
    }
  
    rule clear_sensors {
      select when sensor clear_sensors
  
      always {
        ent:sensors := {}
      }
    }
  
    rule remove_sensor {
      select when sensor unneeded_sensor
  
      pre {
        name = event:attrs{"name"}
        eci = get_sensors(){name}
      }
  
      always {
        clear ent:sensors{name}
        raise wrangler event "child_deletion_request"
          attributes {"eci": eci}
      }
    }
  
  }