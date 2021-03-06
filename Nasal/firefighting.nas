
        
#    HerbyW 2018 for DC-10 Air Tanker

###########################################################################
# Killer grass and other surfaces get now killed by themselfs :)
# by HerbyW 07-2015
# Make the aircraft drive on ground over different surfaces easier

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

##########################################################################
# Retardant system control for deleting fires or making unflamable coridors, MP-retardant will be activ 4.5 seconds after start, so it looks like real!
# Depending on the coverage level the radius of groundcoverage is changing!
# create timer with 1.9 second interval to start dropping
# calculate the corridor depending on CoverageLevel: 40 meter at Level 1 and 120 meter at Level 8

setprop("/controls/retardant[0]/DroppingAmount", 0);
setprop("/controls/retardant[0]/DroppingAmount-left", 0);
setprop("/controls/retardant[0]/CoverageLevel", 1);
setprop("/controls/retardant[0]/LBSpersecond", 3437);

var corridor = 0;

var retardant = maketimer(1.9, func
{ 
    if (getprop("/sim/model/dc10/retardant") > 0 and (getprop("/controls/retardant[0]/DroppingAmount-left") > 500))
  {
          var corridor = math.pow(getprop("/controls/retardant[0]/CoverageLevel"), 0.528) *40 ;
          var drop_pos = geo.aircraft_position();
          settimer( func { wildfire.resolve_retardant_drop(drop_pos, corridor, 1); }, 4.5);
          setprop("/sim/messages/copilot", corridor);
  }     
  }
);

# start the timer (with 2 second inverval)
retardant.start();

#################################################
# Water / Retardant calculations for dropping in Air

# DumpQuantity ist die gesamt abzuwerfende Menge in lbs.
# 3 Regler: /controls/retardant[0]/dump-quantity  1=25% 4=100%
# Wir berechnen zuerst den Durchschnitt der Abwurfmenge aus den 3 Reglern: /controls/retardant[0]/DroppingAmount

setlistener("/controls/retardant[0]/dump-quantity", func 
{
setprop("/controls/retardant[0]/DroppingAmount", (getprop("/controls/retardant[0]/dump-quantity") + getprop("/controls/retardant[1]/dump-quantity") + getprop("/controls/retardant[2]/dump-quantity")) * 9166.6);
});

setlistener("/controls/retardant[1]/dump-quantity", func 
{
setprop("/controls/retardant[0]/DroppingAmount", (getprop("/controls/retardant[0]/dump-quantity") + getprop("/controls/retardant[1]/dump-quantity") + getprop("/controls/retardant[2]/dump-quantity")) * 9166.6);
});

setlistener("/controls/retardant[2]/dump-quantity", func 
{
setprop("/controls/retardant[0]/DroppingAmount", (getprop("/controls/retardant[0]/dump-quantity") + getprop("/controls/retardant[1]/dump-quantity") + getprop("/controls/retardant[2]/dump-quantity")) * 9166.6);
});

# /controls/retardant[0]/dump-speed     1=low level 8=max level (equals 4 times more than CL 1)
# dump-Speed ist das CoverageLevel ist maximal 8, dh in 1 Sekunde 13750 lbs und minimal 1, dh in 1 Sekunde 3437 lbs.
# Wir berechnen zuerst den Durchschnitt des Levels aus den 3 Reglern: /controls/retardant[0]/CoverageLevel

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

# Nun könne wir die LBS pro Sekunde berechnen die abgeworfen werden sollen: /controls/retardant[0]/LBSpersecond

setlistener("/controls/retardant[0]/CoverageLevel", func
{
setprop("/controls/retardant[0]/LBSpersecond", math.pow(getprop("/controls/retardant[0]/CoverageLevel"), 0.66666) * 3437  );
});

#############################################
# Dropping Animation

var Wdrop = 109;

var waterdropping = maketimer( 1, func
{
  if (getprop("/sim/model/dc10/retardant") == 1)    
  {
    
  if ((getprop("/sim/model/dc10/retardant") >0) and (getprop("/sim/weight[2]/weight-lb") > 100) and (getprop("/controls/retardant[0]/DroppingAmount") > 0))
  {
    setprop("/controls/retardant[0]/DroppingAmount-left", getprop("/controls/retardant[0]/DroppingAmount-left") - getprop("/controls/retardant[0]/LBSpersecond"));
    var Wdrop = getprop("/sim/weight[2]/weight-lb") - getprop("/controls/retardant[0]/LBSpersecond");
    setprop("/sim/messages/copilot", "Water is dropping with level");
    setprop("/sim/messages/copilot", getprop("/controls/retardant[0]/CoverageLevel"));
    interpolate("/sim/weight[2]/weight-lb", Wdrop, 1);
    Wload = Wload - 1;
  } 
    if(getprop("/sim/weight[2]/weight-lb") < 100 and getprop("/sim/model/dc10/retardant") >0)
    {
      setprop("/sim/messages/copilot", "Water is out");
      setprop("/sim/model/dc10/retardant", 0);
      setprop("/sim/model/door-positions/waterdoors/position-norm", 0);
    }
    if (getprop("/controls/retardant[0]/DroppingAmount-left") < 3000)
     {
      setprop("/sim/messages/copilot", "Dropping finished");
      setprop("/sim/model/dc10/retardant", 0);
      setprop("/sim/model/door-positions/waterdoors/position-norm", 0);
    }
  }
});  

waterdropping.start();

# We must check if the droppingsystem is set!

setlistener("/sim/model/dc10/retardant", func 
{
  if (getprop("/sim/model/dc10/retardant") == 1 and getprop("/controls/retardant[0]/DroppingAmount") == 0)
  {
     setprop("/sim/model/door-positions/waterdoors/position-norm", 0);
     setprop("/sim/model/dc10/retardant", 0);
     setprop("/sim/messages/copilot", "Droppingsystem is not set"); 
  }
});

# Check if the dropping amount to drop is set correct!

setlistener("/sim/model/dc10/retardant", func 
{
     setprop("/controls/retardant[0]/DroppingAmount-left", getprop("/controls/retardant[0]/DroppingAmount"));
});


#############################################################################
# Water / Retardant loading on ground, only if Parking brakes set!

var Wweight = 0;
var Wload = 1;

var waterloading = maketimer( 1, func
{
     if(getprop("/sim/model/dc10/filling") > 0 and Wload < 111 and (getprop("/controls/gear/brake-parking") == 1) and (getprop("/position/gear-agl-m") < 1))
        
         {                      
         if(getprop("/sim/weight[2]/weight-lb") > 109000)
              {
                setprop("/sim/model/dc10/filling", 0);
                setprop("/sim/weight[2]/weight-lb", 110000);
              }
              else
			       {
			       var Wweight = getprop("/sim/weight[2]/weight-lb") + Wweight + 1000;
                               setprop("/sim/messages/copilot", "Water is loading ...");
			       interpolate("/sim/weight[2]/weight-lb", Wweight, 1);
			       Wload = Wload + 1;
                   }
          }
          else
               if(getprop("/sim/model/dc10/filling") > 0)
               {
               setprop("/sim/model/dc10/filling", 0);
               setprop("/sim/messages/copilot", "Refilling only on Ground possible, set your parking brake...");
               }
});

waterloading.start();


