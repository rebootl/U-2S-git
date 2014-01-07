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

# Trigger

var runloop = 1;

var pogoloop = func {
	
	if (runloop) {
		
		#var altitude_ag = getprop("/position/altitude-agl-ft") or 0.0;
		#var airspeed_kt = getprop("/velocities/airspeed-kt") or 0.0;
		# triggering by compression (this is not as reliable as airspeed but therefor more realistic) !
		# (also triggering by wow could alternatively be tried)
		var pogo_right_comp_ft = getprop("/gear/gear[2]/compression-ft") or 0.0;
		var pogo_left_comp_ft = getprop("/gear/gear[3]/compression-ft") or 0.0;
		
		#if (airspeed_kt >= 70.0) {
		if (pogo_right_comp_ft <= 0.3) {
		
			setprop("/pogos/pogo-r-dropped", 1);			# trigger for animation / submodel
			setprop("/pogos/pogo-r-down", 0);				# trigger for FDM
			
			# (debug-print)
			#print("Pogo Right dropped!");
			
		}
		
		#if (airspeed_kt >= 75.0) {
		if (pogo_left_comp_ft <= 0.3) {
			
			setprop("/pogos/pogo-l-dropped", 1);
			setprop("/pogos/pogo-l-down", 0);
			
			# (debug-print)
			#print("Pogo Left dropped!");
			
		}
		
		var pogo_rdropped = getprop("/pogos/pogo-r-dropped");
		var pogo_ldropped = getprop("/pogos/pogo-l-dropped");
		
		if (pogo_rdropped and pogo_ldropped) {
		
			setprop("/pogos/pogos-dropped", 1);
			
			# (info-print)
			print("Both pogos dropped!");
			
			runloop = 0;
			
			# (debug-print)
			#print("Pogoloop stopped !");
		}
	
	# (debug-print)
	print("Pogoloop is running!");
	
	settimer(pogoloop, 0.3);

	}
}

# Initial function
# (needed to let the trigger props cleanly initiate)
var run_timer = 1;
var init_timer = func {
	if (run_timer) {
		var fdm_ready = getprop("/sim/fdm-initialized") or 0;
		if (fdm_ready){
			pogoloop();
			run_timer = 0;
		}
		settimer(init_timer, 0.5);
	}
}

init_timer();
#pogoloop();

# Reset function for the pogos
var reset_pogos = func {
	# check at the main gear if we're on ground
	var on_ground = getprop("/gear/gear/wow");
	if (on_ground) {
		
		# Stop pogoloop
		runloop = 0;
		
		# Reset all pogo properties
		setprop("/pogos/pogo-r-down", 1);
		setprop("/pogos/pogo-l-down", 1);
		
		setprop("/pogos/pogo-r-dropped", 0);
		setprop("/pogos/pogo-l-dropped", 0);
		
		setprop("/pogos/pogos-dropped", 0);
		
		# (info-print)
		print("Pogos restored.");
		
		# Rerun pogoloop
		runloop = 1;
		
		#pogoloop();
		# give some time to let the compression props initiate
		settimer(pogoloop, 3);
	}
	
	else {
		# Stop pogoloop
		runloop = 0;
		
		# Reset all pogo properties
		setprop("/pogos/pogo-r-down", 0);
		setprop("/pogos/pogo-l-down", 0);
		
		setprop("/pogos/pogo-r-dropped", 1);
		setprop("/pogos/pogo-l-dropped", 1);
		
		setprop("/pogos/pogos-dropped", 1);
	}
	
}

# Set a listener on the system reset function and reset pogos
setlistener("sim/signals/reinit", func {
	# (debug-print)
	print("Got reinit signal!");
	# give some time to let the wow prop initiate (wow is quickly true, when resetting on ground!)
	settimer(reset_pogos, 1);
});


# Put a static model on the ground after the impact (done according to howto)
# Left Pogo

var pogol_node = props.globals.getNode("/impact/pogo-l-path", 1); 			# not really necessary, what for ? get the path of impact data

var pogol_gnd = func(n) { 					 						# what is in this n ?
	
	var pogol = pogol_node.getValue();								# and... not really necessary, what for ? get the path of impact data
	var node = props.globals.getNode(n.getValue(), 1);
	
	geo.put_model("Aircraft/U-2S/Models/Pogo_L-dropped.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.25, 				#+0.25 to ensure the pogo isn't buried
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
		
	#print("Pogo Left put on ground.");									# Debug-Info
	
}

setlistener("/impact/pogo-l-path", pogol_gnd);

# Right Pogo

var pogor_node = props.globals.getNode("/impact/pogo-r-path", 1);

var pogor_gnd = func(n) {
	
	var pogor = pogor_node.getValue();								
	var node = props.globals.getNode(n.getValue(), 1);
	
	geo.put_model("Aircraft/U-2S/Models/Pogo_R-dropped.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.25, 				#+0.25 to ensure the pogo isn't buried
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
		
	#print("Pogo Right put on ground.");									# Debug-Info
	
}

setlistener("/impact/pogo-r-path", pogor_gnd);




## Testing part below..

# adding a model by nasal - test

#var add_model = func {
#	
#	setprop ("models/model/path", "Aircraft/U-2S/Models/Test-Cube.xml");
#	setprop ("models/model/longitude-deg-prop", "/position/longitude-deg");
#	setprop ("models/model/latitude-deg-prop", "/position/latitude-deg");
#	setprop ("models/model/elevation-ft-prop", "/position/altitude-ft");
#	setprop ("models/model/heading-deg-prop", "/orientation/heading-deg");
#	setprop ("models/model/pitch-deg-prop", "/orientation/pitch-deg");
#	setprop ("models/model/roll-deg-prop", "/orientation/roll-deg");
#	props.globals.getNode("models/model/load", 1);
#
#}
#
#add_model();



