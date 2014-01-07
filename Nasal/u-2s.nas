# Nasal script
#-----------------------------------------------------------------------
# This file is part of U-2S.
#
# Copyright 2014 Cem Aydin
# (See Licensing for detailed information.)
#
# Lockheed U-2S for FlightGear flight simulator
#-----------------------------------------------------------------------
#
# Different aircraft routines
#
# I think I took the canopy toggle from the ju52.
#
##

## Open and close canopy animation properties

var toggle_canopy = func {
  if(getprop("/canopy/canopy-pos-norm") > 0) {
   interpolate("/canopy/canopy-pos-norm", 0, 5);
  } else {
    interpolate("/canopy/canopy-pos-norm", 1, 5);
  }
}

## Connect throttle and engine cutoff
# (simply connect the throttle-off switch to the engine cutoff)

var engine_cutoff = func(p) {
    if ( p.getValue() == 1 ) {
        setprop("/controls/engines/engine/cutoff", 1);
    }
    else setprop("/controls/engines/engine/cutoff", 0);
}

setlistener("/controls/engines/throttle-off", engine_cutoff);


## Beacon flash animation properties
var beacon_flash = {
    on: func { setprop(me.prop, 1); },
    off: func { setprop(me.prop, 0); },
    run: func {
        if (me.runloop) {
                settimer(func me.on(), me.ton);
                settimer(func me.off(), me.toff);
                settimer(func me.run(), me.trun);
        }
    },
    start: func(n) {
        if (n.getValue() == 1) {
            me.runloop = 1;
            me.run();
        }
        else {
            me.runloop = 0;
        }
    },
};

var beacon1 = { parents: [beacon_flash], prop: "/controls/lighting/beacon-top-l-flash", ton: 0.7, toff: 1.0, trun: 1.1 };
var beacon2 = { parents: [beacon_flash], prop: "/controls/lighting/beacon-top-r-flash", ton: 0.5, toff: 0.8, trun: 1.1 };
var beacon3 = { parents: [beacon_flash], prop: "/controls/lighting/beacon-bottom-flash", ton: 0.1, toff: 0.4, trun: 1.1 };

setlistener("/controls/lighting/beacon", func(v) { beacon1.start(v);beacon2.start(v);beacon3.start(v); } );
setprop("/controls/lighting/beacon", 1);


## Set additional pushed properties

# Flaps
# (override default control)
controls.flapsDown = func(step) {
    if(step == 0) {
        setprop("/controls/flight/flaps-pushed", 0); # unset pushed prop
        return;
    }
    
    if(props.globals.getNode("/sim/flaps") != nil) {
        stepProps("/controls/flight/flaps", "/sim/flaps", step);
        setprop("/controls/flight/flaps-pushed", step); # set pushed prop
        return;
    }
    
    # Hard-coded flaps movement in 3 equal steps:
    var val = 0.3333334 * step + getprop("/controls/flight/flaps");
    setprop("/controls/flight/flaps", val > 1 ? 1 : val < 0 ? 0 : val);
    setprop("/controls/flight/flaps-pushed", step); # set pushed prop
}

# Speedbrake
# ..
