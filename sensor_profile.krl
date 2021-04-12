ruleset sensor_profile {
    meta {
      shares get_profile
      provides get_profile
    }
  
    global {
      get_profile = function () {
        {
          "name": ent:name,
          "location": ent:location,
          "temperature_threshold": ent:temperature_threshold,
          "recipient_phone_number": ent:recipient_phone_number
        }
      }
    }
  
    rule init {
      select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid
      
      always {
        ent:name := ""
        ent:location := ""
        ent:temperature_threshold := null
        ent:recipient_phone_number := ""
      }
    }
  
    rule update_profile {
      select when sensor profile_updated
  
      pre {
        name = event:attrs{"name"}
        location = event:attrs{"location"}
        temperature_threshold = event:attrs{"temperature_threshold"}.decode()
        recipient_phone_number = event:attrs{"recipient_phone_number"}
      }
      
      always {
        ent:name := name
        ent:location := location
        ent:temperature_threshold := temperature_threshold
        ent:recipient_phone_number := recipient_phone_number
  
        raise wovyn event "config" attributes
          {
            "recipient_phone_number": ent:recipient_phone_number,
            "temperature_threshold": ent:temperature_threshold
          }
      }
  
    }
  }