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
var Blinker = {
    init: func { 
        me.loopid = 1;
        me.switch(1); # (switching on automatically atm)
    },
    on: func { setprop(me.prop, 1); },
    off: func { setprop(me.prop, 0); },
    run: func(id) {
        if (me.loopid == id) {
                settimer(func me.on(), me.ton);
                settimer(func me.off(), me.toff);
                settimer(func me.run(id), me.trun);
        }
    },
    switch: func(n) {
        if (n == 1) {
            me.loopid += 1;
            me.run(me.loopid);
        }
        else {
            me.loopid += 1;
        }
    },
};

var beacon1 = { parents: [Blinker], prop: "/controls/lighting/beacon-top-l-flash", ton: 0.7, toff: 1.0, trun: 1.1 };
var beacon2 = { parents: [Blinker], prop: "/controls/lighting/beacon-top-r-flash", ton: 0.5, toff: 0.8, trun: 1.1 };
var beacon3 = { parents: [Blinker], prop: "/controls/lighting/beacon-bottom-flash", ton: 0.1, toff: 0.4, trun: 1.1 };

beacon1.init();
beacon2.init();
beacon3.init();

setlistener("/controls/lighting/beacon", func(v) { beacon1.switch(v.getValue());beacon2.switch(v.getValue());beacon3.switch(v.getValue()); } );

#setprop("/controls/lighting/beacon", 1);

# stop at reinit
#setlistener("/sim/signals/reinit", func(v) { beacon1.switch(0);beacon2.switch(0);beacon3.switch(0); } );


## Set additional pushed properties
## --> not needed, the flap switch should reflect the position/is coupled to it
# Flaps
# (override default control)
#controls.flapsDown = func(step) {
#    if(step == 0) {
#        setprop("/controls/flight/flaps-pushed", 0); # unset pushed prop
#        return;
#    }
#    
#    if(props.globals.getNode("/sim/flaps") != nil) {
#        stepProps("/controls/flight/flaps", "/sim/flaps", step);
#        setprop("/controls/flight/flaps-pushed", step); # set pushed prop
#        return;
#    }
#    
#    # Hard-coded flaps movement in 3 equal steps:
#    var val = 0.3333334 * step + getprop("/controls/flight/flaps");
#    setprop("/controls/flight/flaps", val > 1 ? 1 : val < 0 ? 0 : val);
#    setprop("/controls/flight/flaps-pushed", step); # set pushed prop
#}

# Speedbrake
# ..
