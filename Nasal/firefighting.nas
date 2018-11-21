
        
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

# Retardant system control for deleting fires, MP-retardant will be activ 4.5 seconds after start, so it looks like real!

# create timer with 2 second interval
var retardant = maketimer(2, func

{ 
    if (getprop("/sim/model/dc10/retardant") > 0)
  {
          var drop_pos = geo.aircraft_position();
          settimer( func { wildfire.resolve_retardant_drop(drop_pos, 40, 1); }, 4.5);
          
  }     
  }
);

# start the timer (with 2 second inverval)
retardant.start();

#############################################################################


# Water / Retardant loading on ground

var Wweight = 0;
var Wload = 1;

var waterloading = maketimer( 1, func
{
     if(getprop("/sim/model/dc10/filling") > 0 and Wload < 111 )
             {  
                if(getprop("/controls/gear/brake-parking") == 1)
		    {
                        if(getprop("/position/gear-agl-m") < 1)
			    {
			       var Wweight = getprop("/sim/weight[2]/weight-lb") + Wweight + 1000;
                               setprop("/sim/messages/copilot", "Water is loading ...");
			       interpolate("/sim/weight[2]/weight-lb", Wweight, 1);
			       Wload = Wload + 1;
                            }
                    }
              }
});

waterloading.start();

#################################################
# Water / Retardant dropping in Air

# /controls/retardant[0]/dump-speed     1=low level 8=max level
# /controls/retardant[0]/dump-quantity  1=25% 4=100%

var DumpQuantity = ((getprop("/controls/retardant[0]/dump-quantity") + getprop("/controls/retardant[1]/dump-quantity") + getprop("/controls/retardant[2]/dump-quantity")) / 3) * 27500;

# DumpQuantity ist die gesamt abzuwerfende Menge in lbs.
# CoverageLevel ist maximal 8, dh in 1 Sekunde 13750 lbs und minimal 1 dh in 1 Sekunde 1718 lbs.
# Also (1718 * CoverageLevel) ist die Abwurfgeschwindigkeit.



setlistener("/controls/retardant[0]/dump-speed", func 
{
setprop("/controls/retardant[0]/CoverageLevel", (getprop("/controls/retardant[0]/dump-speed") + getprop("/controls/retardant[1]/dump-speed") + getprop("/controls/retardant[2]/dump-speed")) / 3);
});

setlistener("/controls/retardant[1]/dump-speed", func 
{
setprop("/controls/retardant[0]/CoverageLevel", (getprop("/controls/retardant[0]/dump-speed") + getprop("/controls/retardant[1]/dump-speed") + getprop("/controls/retardant[2]/dump-speed")) / 3);
});

setlistener("/controls/retardant[2]/dump-speed", func 
{
setprop("/controls/retardant[0]/CoverageLevel", (getprop("/controls/retardant[0]/dump-speed") + getprop("/controls/retardant[1]/dump-speed") + getprop("/controls/retardant[2]/dump-speed")) / 3);
});







var Wdrop = 110;

var waterdropping = maketimer( 1, func
{
  if (getprop("/sim/model/dc10/retardant") == 1)    
  {
    
  if(getprop("/sim/model/dc10/retardant") >0 and (getprop("/sim/weight[2]/weight-lb") > 100))
  {
    var Wdrop = getprop("/sim/weight[2]/weight-lb") - (1718 * getprop("/controls/retardant[0]/CoverageLevel"));
    setprop("/sim/messages/copilot", "Water is dropping ...");
    setprop("/sim/messages/copilot", getprop("/controls/retardant[0]/CoverageLevel"));
    interpolate("/sim/weight[2]/weight-lb", Wdrop, 1);
    Wload = Wload - 1;
  } 
    if(getprop("/sim/weight[2]/weight-lb") < 100 and getprop("/sim/model/dc10/retardant") >0)
    {
      setprop("/sim/messages/copilot", "Water is out");
      setprop("/sim/model/dc10/retardant", 0);
      setprop("/controls/retardant/open", 0);
    }
  }
  else
  { if (getprop("/controls/retardant/open") >0)
    {
    setprop("/controls/retardant/open", 0);
    setprop("/sim/messages/copilot", "Droppingsystem has no power"); 
    }
  }
});  

waterdropping.start();










