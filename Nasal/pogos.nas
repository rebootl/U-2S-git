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
# Pogo fall-off/restore routines
#
##

# Pogo

var Pogo = {
    init: func {
        me.loopid = 1;
        me.trigger(me.loopid);
    },
    trigger: func(id) {
        if (me.loopid == id) {
            # triggering by compression (this is not as reliable as airspeed but therefor more realistic) !
            # (also triggering by wow could alternatively be tried)
            var pogo_comp_ft = getprop(me.comp_prop) or 0.0;
            
            if (pogo_comp_ft <= 0.3) {
                setprop(me.pogo_prop, 0);
                setprop(me.subm_trig, 1); # (needed for the submodel, _has_ to be set true)
                # (info-print)
                print("Pogo dropped.");

                me.loopid += 1;
            }
            
            # (debug-print)
            #print("Pogoloop is running!");
            
            settimer(func me.trigger(id), 0.3);
        }
    },
    restore: func {
        # check at the main gear if we're on ground
        var on_ground = getprop("/gear/gear/wow" or 0);
        if (on_ground) {
            
            # Stop trigger
            me.loopid += 1;
            
            # Reset pogo properties
            setprop(me.pogo_prop, 1);
            setprop(me.subm_trig, 0);
            
            # (info-print)
            print("Pogo restored.");
            
            # Rerun trigger
            #me.runloop = 1;
            # (give some time to let the compression props initiate)
            settimer(func me.trigger(me.loopid), 5);
        }
        else { # (needed when resetting in the air !)
            # Stop trigger
            me.loopid += 1;

            # Reset pogo properties
            setprop(me.pogo_prop, 0);
            setprop(me.subm_trig, 1);
        }
    },
};

# Left and right pogo
var pogo_R = { parents: [Pogo],
                comp_prop: "/gear/gear[2]/compression-ft",
                pogo_prop: "/pogos/pogo-r-down",
                subm_trig: "/pogos/pogo-r-dropped",
};

var pogo_L = { parents: [Pogo],
                comp_prop: "/gear/gear[3]/compression-ft",
                pogo_prop: "/pogos/pogo-l-down",
                subm_trig: "/pogos/pogo-l-dropped",
};

# Initial function
var run_timer = 1;
var init_timer = func {
    if (run_timer) {
        var fdm_ready = getprop("/sim/fdm-initialized") or 0;
        if (fdm_ready){
            pogo_R.init();
            pogo_L.init();
            run_timer = 0;
        }
        settimer(init_timer, 1.0);
    }
}

init_timer();

# Restore function
var reset_pogos = func {
    pogo_R.restore();
    pogo_L.restore();
}

# System reinit
setlistener("sim/signals/reinit", reset_pogos );


# Put a static model on the ground after the impact (done according to howto)
#
# Unfortunately this only works once, even resetting the impact path property,
# doesn't seem to help... currently not worth doing more...

# Left Pogo
# what is in this n ? ==> the property from setlistener!
var pogol_gnd = func(n) {
	
	var node = props.globals.getNode(n.getValue(), 1);
	
	geo.put_model("Aircraft/U-2S/Models/Pogo_L-dropped.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
        #+0.25 to ensure the pogo isn't buried
		node.getNode("impact/elevation-m").getValue()+ 0.25,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);

    # (debug/info print)
    print("Pogo Left put on ground.");
}
setlistener("/impact/pogo-l-path", pogol_gnd);

# Right Pogo
var pogor_gnd = func(n) {
	
	var node = props.globals.getNode(n.getValue(), 1);
	
	geo.put_model("Aircraft/U-2S/Models/Pogo_R-dropped.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
        #+0.25 to ensure the pogo isn't buried
		node.getNode("impact/elevation-m").getValue()+ 0.25,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);

    # (debug/info print)
	print("Pogo Right put on ground.");
}
setlistener("/impact/pogo-r-path", pogor_gnd);
