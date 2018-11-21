
        
#    modified by HerbyW 2018

###########################################################################
# Killer grass and other surfaces get now killed by themselfs :)
# by HerbyW 07-2015
#

setlistener("/fdm/jsbsim/environment/terrain-friction-factor", func { 
  
  if (getprop("/fdm/jsbsim/environment/terrain-friction-factor") > 0.7)
  {
          setprop("/fdm/jsbsim/environment/terrain-friction-factor", 0.8)
  }  
}
);

setlistener("/fdm/jsbsim/environment/terrain-rolling-friction", func { 
  
  if (getprop("/fdm/jsbsim/environment/terrain-rolling-friction") > 0.5)
  {
          
	  setprop("/fdm/jsbsim/environment/terrain-rolling-friction", 0.25)
  }  
}
);



###########################################################################
# wildfire implementation by HerbyW 07-2015  have Fun!!!! modified in 2018 for DC-10 Air Tanker
#

setprop("/environment/wildfire/enabled",1);
setprop("/environment/wildfire/share-events",1);
setprop("/environment/wildfire/save-on-exit",1);
setprop("/environment/wildfire/restore-on-startup",1);
setprop("/environment/wildfire/fire-on-crash",1);
setprop("/environment/wildfire/fire-on-impact",1);
setprop("/environment/wildfire/report-score",1);
setprop("/environment/wildfire/models/enabled",1);
setprop("/environment/wildfire/models/fire-lod",5);
setprop("/environment/wildfire/models/smoke-lod",5);

# make fire with Strg+Shift+MouseClick

setlistener("/sim/signals/click", func {
  if (__kbd.shift.getBoolValue()) {
    if (__kbd.ctrl.getBoolValue()) {
      var click_pos = geo.click_position();
      wildfire.ignite(click_pos);
      setprop("/sim/messages/copilot", "Wildfire in new spot detected!");
    }
  }
});

# Retardant system control for deleting fires
# create timer with 2 second interval
var retardant = maketimer(2, func

{ 
    if (getprop("/sim/model/dc10/retardant") > 0)
  {
          var drop_pos = geo.aircraft_position();
          wildfire.resolve_retardant_drop(drop_pos, 60, 1);
  }     
  }
);

# start the timer (with 2 second inverval)
retardant.start();
