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
# Ejection seat animation (experimental)
# =======================
#
# This tries to implement a simple ejection seat model.
# Originally developed for the U-2S, it should be usable for other FG aircrafts too.
#
# This needs some more work:
# - At present the pilot model is not loaded... (?)
# - Make it more OOP
# - A wiki howto
#
# Some code snippets are from walk.nas (bluebird) by  D. Faber
#
# Date: 2012-07-17
####

#### GLOBAL variables
# Some math definitions

var sin = func(a) { math.sin(a * math.pi / 180.0) }		#  a in degrees
var cos = func(a) { math.cos(a * math.pi / 180.0) }

var DEG2RAD = math.pi / 180;
var RAD2DEG = 180 / math.pi;

var sqrt = func(a) { math.sqrt(a) }

var ln = func(a) { math.ln(a) }
var exp = func(a) { math.exp(a) }

var sinr = func(a) { math.sin(a) }
var cosr = func(a) { math.cos(a) }

var arctanr = func(a, b) { math.atan2(a, b) }			# a in rad, gives a/b NOT b/a as described in reference !


# Set constants

var g = 9.81;

var ERAD = 6378137;							# from walk.nas, trying
var ERAD_deg = 180 / (ERAD * math.pi);				# " "

# ==> Attention only variables(constants) that are never, ever ment to be changed can be
# defined here, the others are defined in the ENGAGEMENT function and then passed over to
# to the CALC function (to maintain simple reset compatibility!) --> or defined in the CALC func. directly

# Global controller var
## Loop control
var timeloop_run = 0;

# Set some initial properties here

setprop("/eject/parachute-deploy", 0.0);
setprop("/eject/hang-ang", 0.0);
setprop("/eject/para-ang", 0.0);
setprop("/eject/parachute-Area", 0.0);



#### Canopy jettison function

var canopy_jettison = func {
	
	setprop("/eject/canopy/force-azimuth-deg", 0);
	setprop("/eject/canopy/force-elevation-deg", 80);
	setprop("/eject/canopy/force-lb", 720);
	
	# Toggle property for the canopy to get jettisoned
	setprop("/eject/canopy/canopy-jettison", 1);
	print("Canopy jettison toggled !");
	
	# Set properties for the external forces applied on submodel
	# (setting these props twice worked best for me, but I don't know why...?)
	
	setprop("/eject/canopy/force-azimuth-deg", 0);
	setprop("/eject/canopy/force-elevation-deg", 80);
	setprop("/eject/canopy/force-lb", 720);
	
	#var action_time = 0.1;
	interpolate("/eject/canopy/force-lb", 0, 0.3);
	#var unload_force = func() {
	#	interpolate("/eject/canopy/force-lb", 0, 0.1);
	#}
	#settimer(unload_force, action_time);
	
}




#### Load the test PILOT - wait for some seconds to let all properties initiate

	# Some words of my testing to figure out the best way to load the pilot
	#
	# Try to get the PILOT model fixed on the airplane first --> does work but the props don't change afterwards
	# --> maybe better: load the pilot normally (integrated to the airplane) then on eject hide it with a select animation
	# and load the eject model afterwards in the script --> model doesn't load really fast enough..
	# solution to test: load the pilot model during the canopy jettison (some seconds/half a second, should be enough)
	# --> still too slow :C or maybe not too slow but there's a time difference between getting the eject pos props
	# during the canopy jettison and starting the delayed function which results in a BAD position difference when flying
	#        ==> preload the model --> put it somewhere never someone would find (northpole) --> doesn't really works
	# much faster...
	# 
	# Solution:
	# ok make a loop func which actualizes the eject props permanently running from the beginning on and
	# load the pilot from nasal putten on this eject props ==> works fluently and nice (only thing that
	# annoys me is having a loop permanently running from beginning of the sim ==> put this loop
	# in the gap of the canopy jettison func ?? but, when loading the pilot on the fly the hole sim was stuttering
	# so maybe better not, preloading the model from nasal is fine for now, otherwise optimize
	# the pilot, reduce polys.....)
	# Leaving as is with the property loop below.
	# Therefore the eject views can also be putten on the eject props from the beginning on.
	#
	#
	# separated the init loop and model load functions, to get a nicer reset possibility
	
	
# Make a loop to actualize eject properties | as long as the eject is not initiated

var delayed_load = func {

	var preloop_run = 1;
	setprop ("eject/boost", 0);
	
	var eject_props = func {
		
		if (preloop_run) {
			
			setprop ("eject/longitude", getprop("/position/longitude-deg"));
			setprop ("eject/latitude", getprop("/position/latitude-deg"));
			setprop ("eject/altitude-ft", getprop("/position/altitude-ft"));
			setprop ("eject/heading", getprop("/orientation/heading-deg"));
			setprop ("eject/pitch", getprop("/orientation/pitch-deg"));
			setprop ("eject/roll", getprop("/orientation/roll-deg"));
			
			var eject_boost = getprop("eject/boost") or 0;
			if (eject_boost) {
				preloop_run = 0;
			}
			
			settimer(eject_props, 0.01);
		}
	}
	
	# Load the pilot model and put it on these props
	
		#to debug
		#setprop ("eject/longitude", getprop("/position/longitude-deg"));
		#setprop ("eject/latitude", getprop("/position/latitude-deg"));
		#setprop ("eject/altitude-ft", getprop("/position/altitude-ft"));
		#setprop ("eject/heading", getprop("/orientation/heading-deg"));
		#setprop ("eject/pitch", getprop("/orientation/pitch-deg"));
		#setprop ("eject/roll", getprop("/orientation/roll-deg"));
	
	setprop ("models/model/path", "Aircraft/U-2S/Models/Pilot.xml");
	setprop ("models/model/longitude-deg-prop", "/eject/longitude");
	setprop ("models/model/latitude-deg-prop", "/eject/latitude");
	setprop ("models/model/elevation-ft-prop", "/eject/altitude-ft");
	setprop ("models/model/heading-deg-prop", "/eject/heading");
	setprop ("models/model/pitch-deg-prop", "/eject/pitch");
	setprop ("models/model/roll-deg-prop", "/eject/roll");
	props.globals.getNode("models/model/load", 1);
	
	eject_props();

}

settimer(delayed_load, 10);




#### Add some CONTROLLERS for Testing

var turn_left = func {
	var old_heading = getprop("/eject/heading");
	var new_heading = old_heading - 1.0;
	setprop("/eject/heading", new_heading);
}

var turn_right = func {
	var old_heading = getprop("/eject/heading");
	var new_heading = old_heading + 1.0;
	setprop("/eject/heading", new_heading);
}

var pitch_down = func {
	var old_pitch = getprop("/eject/pitch");
	var new_pitch = old_pitch - 1.0;
	setprop("/eject/pitch", new_pitch);
}

var pitch_up = func {
	var old_pitch = getprop("/eject/pitch");
	var new_pitch = old_pitch + 1.0;
	setprop("/eject/pitch", new_pitch);
}

var roll_left = func {
	var old_roll = getprop("/eject/roll");
	var new_roll = old_roll - 1.0;
	setprop("/eject/roll", new_roll);
}

var roll_right = func {
	var old_roll = getprop("/eject/roll");
	var new_roll = old_roll + 1.0;
	setprop("/eject/roll", new_roll);
}




#### Parachute LOAD function

var parachute_load = func {
	
	# Load the parachute model 
	#--> changed: integrated the parachute into the pilot model, simpler, and prob. faster
	#setprop ("models/model[1000]/path", "Aircraft/U-2S/Models/Parachute.xml");
	#setprop ("models/model[1000]/longitude-deg-prop", "/eject/longitude");
	#setprop ("models/model[1000]/latitude-deg-prop", "/eject/latitude");
	#setprop ("models/model[1000]/elevation-ft-prop", "/eject/altitude-ft");
	#setprop ("models/model[1000]/heading-deg-prop", "/eject/heading");
	#setprop ("models/model[1000]/pitch-deg-prop", "/eject/pitch");
	#setprop ("models/model[1000]/roll-deg-prop", "/eject/roll");
	#props.globals.getNode("models/model[1000]/load", 1);
	
	# rotate the pilot back to normal orientation within some seconds
	interpolate("eject/pitch", 0.0, 2);
	interpolate("eject/roll", 0.0, 2);
	
	# prop. let the pilot hang down a little bit (rotate animation)
	var hang = func {
		interpolate("/eject/hang-ang", 1.0, 3);
	}
	settimer(hang, 1);
	
	# hide the seat ==> to be done next... --> done in animation xml, controlled by the deploy prop.
	
}




#### Main trajectory / position CALC func (calcs position dep. on time)

var calc_traj = func(vec, speed, ori, pos) {
	
	### Set initial values and controller variables
	
	# Initial values for num. int. (drag)
	var rho_Air = 1.2041;					# [kg/m^3] air density
	var c_w = 0.7;							# [ ] coefficient of drag
	var A = 0.8;							# [m^2] area, surface of the pilot
	var m = 100.0;						# [kg] mass of the pilot w/ ej.seat
	
	var k = ( 1/2*rho_Air*c_w*A );
	
	var x_0 = 0.0;
	var y_0 = 0.0;
	
	# set parachute_check variable
	var chute_deployed = 0;
	var parachute_check = 1;
	
	# Times
	var timestep = 0.01;
	var t = 0.00;
	
	var starttime = getprop("/sim/time/elapsed-sec");
	var endtime = getprop("/sim/time/elapsed-sec");
	
	## Collect the info into hashes
	
	# Times
	var time = {t:t, step:timestep, start:starttime, end:endtime};
	
	# Initial values (c for constants, even if they change later...)
	var c = {rho_Air:rho_Air, c_w:c_w, A:A, m:m, k:k, x:x_0, y:y_0};
	
	## Loop control				--> setting this as global !!
	timeloop_run = 1;
	
	
	### Start the main calculation loop	
	var calc_loop = func {
		
		if (timeloop_run) {
			
			var actual_time = getprop("/sim/time/elapsed-sec");
			
			# Make time counter
			time.t = actual_time - time.start;
			# Make stepwidth for num. Int. (has to be related to real time !)
			var h = actual_time - time.end;
			
			#t = t + timestep;
			
			# set property for debugging
			setprop("/eject/time", time.t);
			setprop("/eject/timestep", h);
			
			### Calculate trajectory in xyz
			#
			# Simple formulas for testing, without any drag
			#
			# x = Vx * t + x0
			#var x = Vx * t;
			
			# y = -1/2*g*t² + Vy*t + y0
			#var y = -1 * (1/2) * g * t * t + Vy * t;
			
			# z = Vz * t + z0
			#var z = Vz * t;
			
			# Use numerical integration instead of simple formulas
			
			var v_1x = vec.vx + h * (-1)*(c.k/c.m)*sqrt(vec.vx*vec.vx + vec.vy*vec.vy) * vec.vx ;
			var v_1y = vec.vy + h * ((-1)*(c.k/c.m)*sqrt(vec.vx*vec.vx + vec.vy*vec.vy) * vec.vy -g) ;
			
			var x_1 = c.x + h * ((vec.vx+v_1x)/2) ;
			var y_1 = c.y + h * ((vec.vy+v_1y)/2) ;
			
			vec.vx = v_1x;		# reset vars for calc
			vec.vy = v_1y;		# ""
			
			c.x = x_1;
			c.y = y_1;
			
			var y = y_1;
			
			var x = x_1 * cos(vec.rot);
			var z = x_1 * sin(vec.rot); #* (-1);
			
			
			### Calculate new position
			#
			## Altitude
			var new_altitude = pos.alt + y;
			
			# m to ft (altitude)
			var new_altitude_ft = new_altitude * (1/0.3048);
			
			## Position
			#
			# Rotate the coordinate system
			
			var phi = ori.head - 90;
			
			var lon_m = x * cos(phi) + z * sin(phi);
			var lat_m = z * cos(phi) - x * sin(phi);
			
			# m to degrees (latitude)
			
			# Correction to get the heigth/altitude involved --> not really a visible consequence
			# the uncorrect behaviour I occured at high altitudes were due to airspeed (IAS) used, which doesn't
			# reflect the real movement at high altitudes due to air density etc. ==> used TAS instead, see above
			var ARAD = ERAD + new_altitude;
			var ARAD_deg = 180 / (ARAD * math.pi);
			
			
			var s_latitude = lat_m * ARAD_deg; 						#* (1 / (60*1852));	# " " it's working !!!
			
			# Calculate new latitude in degrees
			
			var new_latitude = pos.lat + s_latitude;
			
			# m to degrees (longitude)
			
			var s_longitude = lon_m * ARAD_deg / cos(new_latitude); 	# (1 / (60*1852)) * cos(new_latitude); # " " 
			
			# new longitude in degrees
			
			var new_longitude = pos.lon + s_longitude;
			
			
			### Write new values to the properties
			
			setprop ("eject/longitude", new_longitude);
			setprop ("eject/latitude", new_latitude);
			setprop ("eject/altitude-ft", new_altitude_ft);
			
			
			## Write out info props
			setprop("eject/v_y", v_1y);
			setprop("eject/v_x", v_1x);
			
			### Parachute implementation
			
			# Calculate altitude above ground
			# Get the current ground altitude
			var gnd_elev_m = geo.elevation(new_latitude, new_longitude);
			var altitude_gnd_m = new_altitude - gnd_elev_m ;
			
			# SET PARACHUTE_CHECK ABOVE --> set above timeloop
			
			if (parachute_check) {
			
				if ( ( time.t >= 3) and ( altitude_gnd_m <= 1500 ) ) {
					
					### Set variable that parachute is deployed for time loop 
					# (performance prob. better than with a prop)
					chute_deployed = 1;
					
					### Set the parachute-deploy property !!
					# and interpolate it from 0.0 to 1.0 over 3.0 seconds
					# (time the chute takes to open)
					#setprop("/eject/parachute-deploy", 0.0);			# --> is set at the beginning and in reset func.
					# maybe do the interpolation also in the parachute_load func. ? (keep this func. as small as possible)
					interpolate("eject/parachute-deploy", 1.0, 3.0);
					
					# Somewhere here: call a LOAD PARACHUTE func
					parachute_load();
					
					# Stop the checker function
					parachute_check = 0;
					
				}
			
			}
			
			## If the chute is deployed, the c_w value, the area, and k needs to be recalculated
			## ==> optimize this, next step has to be looped only during the recalculation (the time the chute opens, 2.5sec)
			## --> done, see deploy_check below (==> check performance) if bad leaving as it was without
			## (this could be a time-critical moment during runtime.....)
			
			if (chute_deployed) {
				
				# doing this check inside the if, only needs to be done when running (performance)
				# ==> check if performance is ok with this check
				# --> performance seems not too bad but the area isn't fully at 40.5 --> setting check to <1.5 this should
				# give the time neccessary to deploy fully !
				var deploy_check = getprop("eject/parachute-deploy");
				
				if (deploy_check < 1.5) {
					
					# Set new c_w value instantaneously
					c.c_w = 1.33 ;
					
					# Make A, the area, dependent of the deploy prop.
					var A_factor = deploy_check;
					c.A = A_factor * 40.5;
					#print out for debugging
					setprop("/eject/parachute-Area", c.A);
					
					# Recalculate k
					c.k = ( 1/2*c.rho_Air*c.c_w*c.A );
				}
			}
			
			# if we touch ground stop everything, this should be the terminal call
			
			if (altitude_gnd_m < -0.8) {			# the pilot model is 2.8ft (0.8m) above ground
				#stop the timeloop
				timeloop_run = 0;
				
				# (for later implementation: maybe call a terminal function, for example to let the chute
				# fall to ground slowly (rotate animation) (--> done here)
				interpolate("/eject/para-ang", 1.0, 10);
				interpolate("/eject/hang-ang", -0.2, 10);
				# Write a message
				print("You've reached the ground.");
			}
				
			
			# Loop run control --> loop is controlled by above func. --> still doin it
			var check_timeloop = getprop("eject/run-timeloop") or 0;
			if (check_timeloop == 0) {
				timeloop_run = 0;
			}
			
			time.end = getprop("/sim/time/elapsed-sec");
			# Reload loop
			settimer(calc_loop, time.step);
			
		}
		
	}
	
	calc_loop();
}




#### Main ENGAGEMENT function (delayed to give the canopy the time to fall away)

var delayed = func {
	
	## Set properties for new model and load it - testing -> ok
	# ==> moved this to the delayed_load func pilot get's loaded on startup
	# <deleted>
	
	
	## And set a property to hide the original pilot model
	# ==> not necessary anymore, instead set a boost prop
	#
	#setprop ("eject/hide-pilot", 1);
	
	setprop ("eject/boost", 1);
	
	# Write a message
	print("Boost initiated!");
	
	## set properties of the view to eject props ==> not necessary anymore
	# <deleted>
	
	
	## Get the properties for calculation
	
	var longitude = getprop("/eject/longitude") or 0.0;
	var latitude = getprop("/eject/latitude") or 0.0;
	var altitude_ft = getprop("/eject/altitude-ft") or 0.0;
	var heading = getprop("/eject/heading") or 0.0;
	var pitch = getprop("/eject/pitch") or 0.0;
	var roll = getprop("/eject/roll") or 0.0;
	
	#var airspeed_kt = getprop("/velocities/airspeed-kt") or 0.0;
	# Trying to get TAS instead --> not absolutely perfect, but I would say OK
	var airspeed_kt = getprop("/instrumentation/airspeed-indicator/true-speed-kt") or 0.0;
	
	# Get ground elev. for autom. parachute opening at 5000ft above ground
	#var ground_elev_ft = getprop("/position/ground-elev-ft") or 0.0; --> getting the correct value in the timeloop
	
	# Convert to SI units
	var altitude = altitude_ft * 0.3048;
	var airspeed = airspeed_kt * 0.514444;
	
	## Set and calculate the initial vectors: x = forward, y = up, z = left
	
	var VAircraft = airspeed;
	var VEject = 30;
	
	# VxAircraft = Aircraft velocity * cos(pitch)
	var VxAircraft = VAircraft * cos(pitch);
	
	# VyAircraft = VAircraft * sin(pitch) Testing *-1.0 to correct direction ==> flying down ok flying up eject goes down
	var VyAircraft = VAircraft * sin(pitch);
	
	# Vxy = VEject * cos(roll)
	var Vxy = VEject * cos(roll);
	
	# VxEject = Vxy * sin(pitch) Attention: * -1 to correct direction !
	var VxEject = Vxy * sin(pitch) * -1.0;
	
	# Vx = VxAircraft + VxEject
	var Vx = VxAircraft + VxEject;
	
	# VyEject = Vxy * cos(pitch)
	var VyEject = Vxy * cos(pitch);
	
	# Vy = VyEject + VyAircraft
	var Vy = VyEject + VyAircraft;
	
	# Vz = VEject * sin(roll) Attention * -1 to correct direction !
	var Vz = VEject * sin(roll) * -1.0;
	
	
	# Calculate Vxres and rot for num. int.
	var v_0x = sqrt(Vx*Vx + Vz*Vz);
	var v_0y = Vy;
	
	var rot_r = arctanr(Vz, Vx);
	var rot = RAD2DEG * rot_r;
	
	
	## Write out properties for debugging / info (only info props, func. works with the variables instead)
	
	setprop("/eject/rot", rot);
	
	setprop("/eject/Vx", Vx);
	setprop("/eject/Vy", Vy);
	setprop("/eject/Vz", Vz);
	
	setprop("/eject/Vxy", Vxy);
	setprop("/eject/VyEject", VyEject);
	setprop("/eject/VyAircraft", VyAircraft);
	
	setprop("/eject/VxEject", VxEject);
	setprop("/eject/VxAircraft", VxAircraft);
	
	# Loop control
	setprop("/eject/run-timeloop", 1);	
	
	## Collect all the info into hashes to hand them over to the CALC loop
	# Position
	var pos = {alt_ft:altitude_ft, alt:altitude, lon:longitude, lat:latitude};
	
	# Orientation
	var ori = {head:heading, pitch:pitch, roll:roll};
	
	# Speeds
	var speed = {tas_kt:airspeed_kt, tas:airspeed};
	
	# Calculated Vectors
	var vec = {vx:v_0x, vy:v_0y, rot:rot};
	
	
	## Call the trajectory CALC loop
	
	calc_traj(vec, speed, ori, pos);
	
}




#### Create the MAIN eject function

var eject = func() {
	
	# Only do something if it wasn't already done (avoid multiple instances!)
	var init_check = getprop ("eject/initiated") or 0;
	if (init_check == 0) {
		
		# Set a property that ejection was initiated
		setprop ("eject/initiated", 1);
		
		# Write out message
		print("Ejection initiated !!!");
		
		## Call the canopy jettison function
		canopy_jettison();
		
		## Wait some time to let it fall away, construct a sleep function
		
		print("Wait to let the canopy jettison...");
		var sleeptime = 4; 		# Time n seconds for testing, can be reduced at any time later
		
		## During this time load the pilot model ==> resulted in a ugly time gap, moved back into delayed func
		
		# Switch to the eject views automatically, don't have time to do this manually
		# in a critical situation, doin this for the first three views
		
		var curr_view = getprop("sim/current-view/view-number") or 0;
		# internal
		if (curr_view == 0) {
			setprop("sim/current-view/view-number", 10);
		}
		# external
		if (curr_view == 1 or curr_view == 2) {
			setprop("sim/current-view/view-number", 9);
		}
		
		# Call the ENGAGEMENT function (delayed)
		
		settimer(delayed, sleeptime);
		
	}
}




#### Make a RESET function

var reset_eject = func() {
	
	# Check if ejection was initiatet
	var eject_init = getprop("eject/initiated") or 0;
	
	if (eject_init) {
		
		# Remove parachute model ==> not working ?? --> parachute get's integrated into pilot model
		#props.globals.getNode("models", 1).removeChild("model[1000]", 0);
		
		# Reset parachute deploy prop
		setprop("/eject/parachute-deploy", 0.0);
		setprop("/eject/hang-ang", 0.0);
		setprop("/eject/para-ang", 0.0);
		setprop("/eject/parachute-Area", 0.0);
		
		# Reset boost property
		setprop("eject/boost", 0);
		
		# Reset init property
		setprop("eject/initiated", 0);
		
		# Reset canopy jettison property
		setprop("/eject/canopy/canopy-jettison", 0);
		
		# Stop timeloop --> loop is controlled by vars.
		setprop("/eject/run-timeloop", 0);
		timeloop_run = 0;
		
		# Restart init loop
		delayed_load();
	
	}
}


# Set a listener on the system reinit (from walk.nas)
setlistener("sim/signals/reinit", func {
	reset_eject();
});



