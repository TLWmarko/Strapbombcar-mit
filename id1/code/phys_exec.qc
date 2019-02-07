vector(vector c_maxs, vector c_mins, vector c_org) Clamp =
{
	local vector ret_vec;

	ret_vec_x = min(c_maxs_x, c_org_x);
	ret_vec_x = max(c_mins_x, ret_vec_x);
	ret_vec_y = min(c_maxs_y, c_org_y);
	ret_vec_y = max(c_mins_y, ret_vec_y);
	ret_vec_z = min(c_maxs_z, c_org_z);
	ret_vec_z = max(c_mins_z, ret_vec_z);
	return ret_vec;
};

void(entity targ, vector vel) setvelocity =
{
	targ.physobj_flags = targ.physobj_flags | PHFLAGS_FORCE;
	targ.velocity = vel;
};

void(entity targ, float in_mass, vector inforce, vector hitspot, vector normal) Phys_Force =
{
	local float dot;
	local float t_mass;
	local float closest_dist;
	local vector force;
	local entity part;

	if (!targ.physobj_mass || !in_mass)
		return;

	if (targ.classname == "hitmodel")
		targ = targ.owner;

	t_mass = min(1, in_mass/targ.physobj_mass);
	targ.physobj_flags = targ.physobj_flags | PHFLAGS_FORCE;
	targ.physobj_flags = targ.physobj_flags - (targ.physobj_flags & PHFLAGS_RESTING);
	targ.flags = targ.flags - (targ.flags & FL_ONGROUND);

	if (targ.physobj_particlelist)
	{
		closest_dist = 999999999;
		part = targ.physobj_particlelist;
		while (part)
		{
			part.force_calcdist = vlen(part.origin - hitspot);
			closest_dist = min(part.force_calcdist, closest_dist);
			part = part.physobj_next;
		}
		part = targ.physobj_particlelist;
		while (part)
		{
			part.force_calcscale = closest_dist/part.force_calcdist;
			part = part.physobj_next;
		}
		targ = targ.physobj_particlelist;
	}
	while(targ)
	{
		dot = normalize(inforce)*normal;
		force = normal*vlen(inforce)*dot*t_mass*targ.force_calcscale;
		setvelocity(targ, targ.velocity + force*0.8); // hack to soften things up a bit, before I figure out wtf is wrong
		//targ.velocity = targ.velocity + force*0.8; // hack to soften things up a bit, before I figure out wtf is wrong
		targ.physobj_flags = targ.physobj_flags - (targ.physobj_flags & PHFLAGS_RESTING);
		targ.flags = targ.flags - (targ.flags & FL_ONGROUND);
		targ = targ.physobj_next;
	}
};

// Fixes the worst cases of being stuck inside walls and objects
void(entity targ) Phys_CheckStatus =
{
	local float inverse_frametime, dot, success, best_dot, best_dist;
	local vector best_normal;
	local entity stick, part, oself, t_ent;

	oself = self;
	inverse_frametime = 1 / frametime;
	if (targ)
	{
		part = targ;
		self = targ.realowner;
	}
	else
		part = self.physobj_particlelist;
	while(part)
	{
		if (part.physobj_flags & PHFLAGS_FORCE)
		{
			self.physobj_flags = self.physobj_flags | PHFLAGS_FORCE;
			part.physobj_flags = part.physobj_flags - (part.physobj_flags & PHFLAGS_FORCE);
		}
		// Wake up in case we got pushed
		if (part.origin != part.pushorigin)
		{
			self.physobj_flags = self.physobj_flags - (self.physobj_flags & PHFLAGS_RESTING);
			part.physobj_flags = part.physobj_flags - (part.physobj_flags & PHFLAGS_RESTING);
		}

		tracebox(part.origin, part.mins, part.maxs, part.origin, TRUE, part);
		if (trace_startsolid) // we got jammed by a hitmodel or are generally stuck
		{
			part.solid = SOLID_NOT;
			part.movetype = MOVETYPE_NONE;
			part.flags = part.flags - (part.flags & FL_FLY);
			part.physobj_movetype = MOVE_WORLDONLY;
			part.physobj_flags = part.physobj_flags | PHFLAGS_BLOCKED;
			self.physobj_flags = self.physobj_flags - (self.physobj_flags & PHFLAGS_RESTING);
			part.physobj_flags = part.physobj_flags - (part.physobj_flags & PHFLAGS_RESTING);
			success = FALSE;
			best_dot = 0;
			best_normal = '0 0 0';
			best_dist = 0;
			t_ent = world;
			stick = self.physobj_sticklist;
			while (stick) // trace from any of the free 
			{
				if (stick.physobj_p1 == part)
				{
					if (stick.physobj_p2.relative_size >= stick.physobj_p1.relative_size)
						tracebox(stick.physobj_p2.origin, stick.physobj_p2.mins, stick.physobj_p2.maxs, stick.physobj_p1.origin, FALSE, stick.physobj_p2);
					if (trace_fraction < 1)
					{
						dot = normalize(stick.physobj_p1.origin-stick.physobj_p2.origin)*trace_plane_normal*-1;
						if (dot > best_dot)
						{
							t_ent = trace_ent;
							best_dot = dot;
							best_dist = vlen(trace_endpos - part.origin);
							best_normal = trace_plane_normal;
						}
					}
				}
				else if (stick.physobj_p2 == part)
				{
					if (stick.physobj_p1.relative_size >= stick.physobj_p2.relative_size)
						tracebox(stick.physobj_p1.origin, stick.physobj_p1.mins, stick.physobj_p1.maxs, stick.physobj_p2.origin, FALSE, stick.physobj_p1);
					if (trace_fraction < 1)
					{
						dot = normalize(stick.physobj_p2.origin-stick.physobj_p1.origin)*trace_plane_normal*-1;
						if (dot > best_dot)
						{
							t_ent = trace_ent;
							best_dot = dot;
							best_dist = vlen(trace_endpos - part.origin);
							best_normal = trace_plane_normal;
						}
					}
				}
				stick = stick.physobj_next;
			}
			if (best_dot)
			{
				part.velocity = best_normal*best_dist*best_dot*inverse_frametime;
				//Phys_Force(hitmodel, self.physobj_mass*part.part_mass, part.velocity*-0.01, part.origin+part.velocity*frametime, trace_plane_normal); // lolhax
			}
		}
		else
		{
			part.solid = SOLID_TRIGGER;
			part.movetype = MOVETYPE_STEP;
			part.flags = part.flags | FL_FLY;
			part.physobj_flags = part.physobj_flags - (part.physobj_flags & PHFLAGS_BLOCKED);
			part.physobj_movetype = MOVE_NORMAL;
		}
		if (!targ)
			part = part.physobj_next;
		else
			part = world;
	}
	self = oself;
};

// Particle acceleration, such as gravity, buoyancy
void(float fscale, float ftime) Phys_Acceleration =
{
	local float pl, sp;
	local float len, frac, dot;
	local vector spring, v;
	local entity part, e;

	part = self.physobj_particlelist;
	while(part)
	{
		tracebox(part.origin, part.mins, part.maxs, part.origin, FALSE, part);
		if (trace_inwater)
			part.velocity_z = part.velocity_z + sv_gravity*part.physobj_buoyancy*ftime*fscale; // Buoyancy
		else
			part.velocity_z = part.velocity_z - sv_gravity*part.gravity*ftime*fscale; // Gravity
		//if (!!part.physobj_spring) // for some reason this returns TRUE if the particle has springs (if(vector) doesn't work)
		if (part.flags & FL_ONGROUND)
		if (part.physobj_flags & PHFLAGS_SPRING_TOUCH)
		{
		
			Matrix_Multiply(part.physobj_spring, '0 0 0', '0 0 0', part.lmat_forward, part.lmat_left, part.lmat_up);
			spring = matrix_forward;
			//spring = part.physobj_spring;
			//print(ftos(vlen(spring)), "\n");
			//tracebox(part.origin, part.mins, part.maxs, part.origin + spring, FALSE, part);
			//v = part.origin + spring;
			//v = normalize(part.physobj_hitplane)*(normalize(part.physobj_hitplane)*normalize(v))*vlen(v);
			//print (ftos(vlen(v)), " v ", ftos(vlen(part.physobj_hitplane)), " hitplane\n");
			//pl = vlen(part.physobj_hitplane);
			//sp = vlen(v);
			//frac = 1-(pl/sp);
			//len = (vlen(spring)*(1-part.physobj_hitfrac))/vlen(spring);
			
			len = max(sv_gravity*0.5, sv_gravity*1.5*(1-part.physobj_floor_frac));
			//len = max(len*sv_gravity*1.2, len*sv_gravity*2);
			//len = 1;
			//print(ftos(len), "\n");
			v = normalize(spring)*len*ftime*fscale;
			part.velocity = part.velocity - v;
			//FIXME
			part.velocity = part.velocity + normalize(v)*part.physobj_floor_frac*100*ftime*fscale;
			/*
			e = self.physobj_particlelist;
			while (e)
			{
				if (e != part)
				{
					dot = normalize(part.origin - e.origin)*normalize(spring);
					if (dot > 0)
						e.velocity = e.velocity - v*dot*e.part_mass;
				}
				e = e.physobj_next;
			}
			*/
		}
		part = part.physobj_next;
	}
};

// Run constraints on all particles
void(float iterations, float ftime) Phys_Constraints =
{
	local float i;
	local float offsetlength, diff;
	local float inverse_frametime;
	local vector offset;
	local entity part, stick;
	local entity p1, p2;

	inverse_frametime = 1 / ftime;
	// Build future positions for particles
	part = self.physobj_particlelist;
	while (part)
	{
		part.destorigin = part.origin + part.velocity * ftime;
		part = part.physobj_next;
	}
	// Run constraints multiple times to calm them down
	while (i < iterations)
	{
		i = i + 1;
		stick = self.physobj_sticklist;
		while(stick)
		{
			p1 = stick.physobj_p1;
			p2 = stick.physobj_p2;
			offset = p1.destorigin - p2.destorigin;
			offsetlength = vlen(offset);
			diff = (offsetlength-stick.stick_preferredlength)/(offsetlength*(p1.physobj_inversemass+p2.physobj_inversemass));
			p1.destorigin = p1.destorigin - p1.physobj_inversemass*offset*diff;
			p2.destorigin = p2.destorigin + p2.physobj_inversemass*offset*diff;	
			stick = stick.physobj_next;
		}
	}
	// Convert back from future positions to velocities again
	part = self.physobj_particlelist;
	while (part)
	{
		part.velocity = (part.destorigin - part.origin) * inverse_frametime;
		part = part.physobj_next;
	}
};

// Check if we're touching the ground
void() Phys_CheckOnGround =
{
	local vector spring;
	local entity part;

	part = self.physobj_particlelist;
	while (part)
	{
		tracebox(part.origin, part.mins, part.maxs, part.origin + '0 0 -1', FALSE, part);
		if (!!part.physobj_spring) // check for springs
		{
			Matrix_Multiply(part.physobj_spring, '0 0 0', '0 0 0', part.lmat_forward, part.lmat_left, part.lmat_up);
			spring = matrix_forward;
			//spring = part.physobj_spring;
			tracebox(part.origin, part.mins, part.maxs, part.origin + spring, FALSE, part);
			//print(ftos(trace_fraction), "\n");
			if (trace_fraction < 1)
				part.physobj_flags = part.physobj_flags | PHFLAGS_SPRING_TOUCH;
			else
				part.physobj_flags = part.physobj_flags - (part.physobj_flags & PHFLAGS_SPRING_TOUCH);
		}
		// We're touching the ground
		if (trace_fraction < 1 && trace_plane_normal_z > 0.7)
		{
			part.flags = part.flags | FL_ONGROUND;
			// FIXME: this almost works, and it'd be awesome to have
			//part.physobj_floor_plane = trace_plane_normal*(trace_plane_normal*normalize(trace_endpos))*vlen(trace_endpos);
			part.physobj_floor_plane_normal = trace_plane_normal;
			part.physobj_floor_frac = trace_fraction;
		}
		else
			part.flags = part.flags - (part.flags & FL_ONGROUND);
		part = part.physobj_next;
	}
};

// Apply water friction, stiction
void(float ftime) Phys_Deceleration =
{
	local float vel, st, dot;
	local entity part;

	part = self.physobj_particlelist;
	while (part)
	{
		if (part.flags & FL_ONGROUND)
		{
			// Stiction
			if (part.physobj_stiction > 0)
			{
				vel = vlen(part.velocity);
				if (vel <= part.physobj_stiction) // stiction occurs when moving slow enough
				{
					st = vel/part.physobj_stiction;
					//part.velocity = part.velocity*st*ftime;
					part.velocity = part.velocity*st;
				}
			}
			// Directional ground friction
			dot = part.physobj_floor_plane_normal*normalize(part.velocity)*-1;
			if (part.physobj_friction_ground_x)
				part.velocity = part.velocity - part.lmat_forward*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_forward)*part.physobj_friction_ground_x*2*ftime;//(1+dot)*ftime;
			if (part.physobj_friction_ground_y)
				part.velocity = part.velocity - part.lmat_left*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_left)*part.physobj_friction_ground_y*2*ftime;//(1+dot)*ftime;
			if (part.physobj_friction_ground_z)
				part.velocity = part.velocity - part.lmat_up*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_up)*part.physobj_friction_ground_z*2*ftime;//(1+dot)*ftime;
			//print(ftos(vlen(part.lmat_up*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_up)*part.physobj_friction_ground_z*(1+dot)*ftime)), "\n");
		}
		tracebox(part.origin, part.mins, part.maxs, part.origin, TRUE, part);
		// Water friction
		//if (trace_inwater)
		if (pointcontents(part.origin) < CONTENT_SOLID)
		{
			if (part.physobj_friction_water_x)
				part.velocity = part.velocity - part.lmat_forward*vlen(part.velocity)*normalize(part.velocity)*part.lmat_forward*part.physobj_friction_water_x*ftime;
			if (part.physobj_friction_water_y)
				part.velocity = part.velocity - part.lmat_left*vlen(part.velocity)*normalize(part.velocity)*part.lmat_left*part.physobj_friction_water_y*ftime;
			if (part.physobj_friction_water_z)
				part.velocity = part.velocity - part.lmat_up*vlen(part.velocity)*normalize(part.velocity)*part.lmat_up*part.physobj_friction_water_z*ftime;
		}
		// Air friction
		else if (!trace_startsolid)
		{
			if (part.physobj_friction_air_x)
				part.velocity = part.velocity - part.lmat_forward*vlen(part.velocity)*normalize(part.velocity)*part.lmat_forward*part.physobj_friction_air_x*ftime;
			if (part.physobj_friction_air_y)
				part.velocity = part.velocity - part.lmat_left*vlen(part.velocity)*normalize(part.velocity)*part.lmat_left*part.physobj_friction_air_y*ftime;
			if (part.physobj_friction_air_z)
				part.velocity = part.velocity - part.lmat_up*vlen(part.velocity)*normalize(part.velocity)*part.lmat_up*part.physobj_friction_air_z*ftime;
		}
		part = part.physobj_next;
	}
};

void(entity part, entity object) Phys_ObjectRemoveParticle;

// Velocity Verlet physics, meant to be used for all moving entities in the game
void(float ftime) Phys_Move =
{
	local float bump, it;
	local float t;
	local float dot;
	local float stuck;
	local vector test_org;
	local vector spring;
	local entity part, killme;

	local vector save_endpos;
	local vector save_normal;
	local float save_fraction;
	local entity save_ent;

	part = self.physobj_particlelist;
	if (!part)
		part = self;
	while(part)
	{
		part.oldorigin = part.origin;
		bump = 0;
		it = 0;
		stuck = FALSE;
		t = ftime;
		test_org = part.origin;
		while (bump < 24)
		{
			// let's test if we're stuck first
			it = 0;
			bump = bump + 1;
			if (!stuck && !(part.physobj_flags & PHFLAGS_BLOCKED))
			{
				tracebox(part.origin, part.mins, part.maxs, part.origin, TRUE, part);
				if (trace_startsolid)
					stuck = TRUE;
			}
			while (stuck && it < 16)
			{
				it = it + 1;
				test_org = part.origin + randomvec()*0.125; // let's nudge the origin a bit
				tracebox(test_org, part.mins + '-0.05 -0.05 -0.05', part.maxs + '0.05 0.05 0.05', test_org, TRUE, part);
				if (!trace_startsolid)
				{
					stuck = FALSE;
					break;
				}
				else
					test_org = part.origin;
			}
			tracebox(test_org, part.mins, part.maxs, test_org + part.velocity*t, part.physobj_movetype, part);
			save_fraction = trace_fraction;
			save_normal = trace_plane_normal;
			save_endpos = trace_endpos;
			// check if the move was valid
			if (!(part.physobj_flags & PHFLAGS_BLOCKED))
			{
				tracebox(trace_endpos, part.mins, part.maxs, trace_endpos, TRUE, part);
				if (trace_startsolid)
				{
					stuck = TRUE;
					continue; // nope, start over
				}
			}
			trace_endpos = save_endpos;
			trace_plane_normal = save_normal;
			trace_fraction = save_fraction;
			t = t*(1-trace_fraction);
			dot = trace_plane_normal*normalize(part.velocity)*-1;
			/*if (trace_fraction == 1)
			if (part.flags & FL_ONGROUND && part.physobj_flags & PHFLAGS_SPRING_TOUCH)
			{
				
			}*/
			if (trace_fraction < 1)
			{
				// Check for stair steps
				if (part.physobj_stepup > 0 && trace_plane_normal_z <= 0)
				{
					save_fraction = trace_fraction;
					save_normal = trace_plane_normal;
					save_endpos = trace_endpos;
					save_ent = trace_ent;
					tracebox(trace_endpos + '0 0 1'*part.physobj_stepup, part.mins, part.maxs, trace_endpos + '0 0 1'*part.physobj_stepup + part.velocity * t, part.physobj_movetype, part);
					if (!trace_startsolid && trace_fraction > 0.0001)
					{
						t = t * (1 - trace_fraction);
						save_ent = trace_ent;
						save_normal = trace_plane_normal;
						tracebox(trace_endpos, part.mins, part.maxs, trace_endpos + '0 0 -1'*part.physobj_stepup, part.physobj_movetype, part);
						trace_fraction = save_fraction;
						trace_ent = save_ent;
					}
					else
					{
						trace_endpos = save_endpos;
						trace_plane_normal = save_normal;
						trace_fraction = save_fraction;
						trace_ent = save_ent;
					}
				}
				// Let's push stuff we hit
				Phys_Force(trace_ent, part.physobj_mass*part.part_mass, part.velocity, trace_endpos, save_normal);
				// Impact event
				self.physobj_impactevent(part, trace_ent);
				// Bounce
				part.velocity = part.velocity - part.physobj_bounce*(trace_plane_normal * (trace_plane_normal * part.velocity));
				// Directional ground friction
				/*if (part.physobj_friction_ground_x)
					part.velocity = part.velocity - part.lmat_forward*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_forward)*part.physobj_friction_ground_x*(1+dot)*ftime;
				if (part.physobj_friction_ground_y)
					part.velocity = part.velocity - part.lmat_left*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_left)*part.physobj_friction_ground_y*(1+dot)*ftime;
				if (part.physobj_friction_ground_z)
					part.velocity = part.velocity - part.lmat_up*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_up)*part.physobj_friction_ground_z*(1+dot)*ftime;*/
			}
			/*else if (part.flags & FL_ONGROUND && part.physobj_flags & PHFLAGS_SPRING_TOUCH) // do special friction for springs
			{
				//dot = normalize(part.physobj_hitplane)*normalize(part.velocity)*-1;
				dot = 1;
				if (part.physobj_friction_ground_x)
					part.velocity = part.velocity - part.lmat_forward*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_forward)*part.physobj_friction_ground_x*(1+dot)*ftime;
				if (part.physobj_friction_ground_y)
					part.velocity = part.velocity - part.lmat_left*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_left)*part.physobj_friction_ground_y*(1+dot)*ftime;
				if (part.physobj_friction_ground_z)
					part.velocity = part.velocity - part.lmat_up*vlen(part.velocity)*(normalize(part.velocity)*part.lmat_up)*part.physobj_friction_ground_z*(1+dot)*ftime;
			}*/
			if (trace_fraction >= 0.0001)
			{
				setorigin(part, trace_endpos);
				force_retouch = 2;
				test_org = part.origin;
			}
			if (trace_fraction == 1)
				break;
		}
		part.pushorigin = part.origin;
		if (!(part.physobj_flags & PHFLAGS_BLOCKED))
		{
			if (vlen(part.origin - part.oldorigin) < ftime*5)
				part.physobj_flags = part.physobj_flags | PHFLAGS_RESTING;
			else
				part.physobj_flags = part.physobj_flags - (part.physobj_flags & PHFLAGS_RESTING);
		}
		if (part.physobj_flags & PHFLAGS_KILLME)
		{
			killme = part;
			part = part.physobj_next;
			Phys_ObjectRemoveParticle(killme, self);
		}
		else
			part = part.physobj_next;
	}
};

void() Phys_CheckRestState =
{
	local float f, len;
	local entity part, stick;

	if (self.physobj_flags & PHFLAGS_ATTACHED)
	{
		self.physobj_flags = self.physobj_flags - (self.physobj_flags & PHFLAGS_RESTING);
		return;
	}

	f = 0;
	part = self.physobj_particlelist;
	while(part)
	{
		if (!(part.physobj_flags & PHFLAGS_RESTING))
		{
			f = 0;
			break;
		}
		if (part.flags & FL_ONGROUND)
			f = f + 1;
		part = part.physobj_next;
	}

	if (f > 2 && !(self.physobj_flags & PHFLAGS_RESTING))
	{
		stick = self.physobj_sticklist;
		while (stick)
		{
			len = vlen(stick.physobj_p1.origin-stick.physobj_p2.origin);
			if (len < stick.stick_preferredlength*0.95 && len > stick.stick_preferredlength*1.05)
			{
				//self.physobj_staticlist.colormod = '1 1 1';
				self.physobj_flags = self.physobj_flags - (self.physobj_flags & PHFLAGS_RESTING);
				return;
			}
			stick = stick.physobj_next;
		}
		self.physobj_flags = self.physobj_flags | PHFLAGS_RESTING;
		//self.physobj_staticlist.colormod = '2 2 2';
		part = self.physobj_particlelist;
		while(part)
		{
			setorigin(part, part.oldorigin);
			part.pushorigin = part.origin;
			part = part.physobj_next;
		}
	}
	else if (f <= 2)
	{
		//self.physobj_staticlist.colormod = '1 1 1';
		self.physobj_flags = self.physobj_flags - (self.physobj_flags & PHFLAGS_RESTING);
	}
}

float() Phys_CheckCollisionDot =
{
	local float dot, highest_dot;
	local entity part;

	part = self.physobj_particlelist;
	while(part)
	{
		tracebox(part.origin, part.mins, part.maxs, part.origin + part.velocity*frametime, part.physobj_movetype, part);
		dot = trace_plane_normal*normalize(part.velocity)*-1;
		if (dot > highest_dot)
		{
			highest_dot = dot;
		}
		part = part.physobj_next;
	}
	return highest_dot;
};

// The think function for our physics objects in the game
void() Phys_ObjectThink =
{
	local float f, ftime, steps, iterations, coldot;
	local float best_vel, best_len, vel_limit, vel;
	local entity part, hitmodel, static;

	// Run every frame
	self.nextthink = time;

	sv_gravity = cvar("sv_gravity");

	Phys_CheckStatus(world); // Check in case we got pushed, blocked by a hitmodel or otherwise stuck
	Phys_CheckOnGround(); // Check onground status in case we need to wake up the object
	Phys_CheckRestState(); // See above

	if (!(self.physobj_flags & PHFLAGS_RESTING))
	{
		// Figure out the amount of steps needed to abide with the length of the shortest stick
		// This is used to prevent sign errors
		// Limit the amount of steps based on the angle of collision, unless there was a force change
		coldot = 0;
		if (!(self.physobj_flags & PHFLAGS_FORCE))
			coldot = Phys_CheckCollisionDot();
		// Limit velocities to not cause too many steps to occur
		//vel_limit = cvar("phys_maxvelocity");
		iterations = max(1, cvar("phys_constraints_linear_iterations"));
		best_len = 999999999;
		best_vel = 0;
		part = self.physobj_particlelist;
		while(part)
		{
			vel = vlen(part.velocity);
			f = 1;
			if (vel_limit > 0)
				f = min(1, vel_limit/vel);
			part.velocity = part.velocity*f;
			best_vel = max(vlen(part.velocity*frametime), best_vel);
			best_len = min(part.stick_preferredlength, best_len);
			part = part.physobj_next;
		}
		steps = max(1, ceil((best_vel/best_len)*coldot));
		ftime = 1/steps;
		ftime = ftime*frametime;

		// Let's run some physics
		while(steps)
		{
			steps = steps - 1;
			Phys_CheckOnGround();
			Phys_Acceleration(0.5, ftime);
			Phys_Constraints(iterations, ftime);
			Phys_Deceleration(ftime);
			Phys_Move(ftime);
			Phys_Acceleration(0.5, ftime);
		}
		self.physobj_flags = self.physobj_flags - (self.physobj_flags & PHFLAGS_FORCE);

		//If movement was very minor, and atleast three particles are on the ground, let's stick to the floor
		Phys_CheckRestState();

		// calculate an object matrix from the first three particles, used for orientation (magic)
		Matrix_CalculateObjectMatrix(self);
		self.lmat_forward = matrix_forward;
		self.lmat_left = matrix_left;
		self.lmat_up = matrix_up;

		// Update particle orientations
		part = self.physobj_particlelist;
		while(part)
		{
			Matrix_Multiply(part.relative_forward, part.relative_left, part.relative_up, self.lmat_forward, self.lmat_left, self.lmat_up);
			part.lmat_forward = matrix_forward;
			part.lmat_left = matrix_left;
			part.lmat_up = matrix_up;
			// Update euler angles for viewing ingame
			part.angles = vectoangles2(matrix_forward, matrix_up);
			if (part.physobj_flags & PHFLAGS_BSPMODEL)
				part.angles_x = part.angles_x*-1;
			part = part.physobj_next;
		}
		// Update static object orientations and origins
		static = self.physobj_staticlist;
		while (static)
		{
			Matrix_Multiply(static.relative_forward, static.relative_left, static.relative_up, self.lmat_forward, self.lmat_left, self.lmat_up);
			static.lmat_forward = matrix_forward;
			static.lmat_left = matrix_left;
			static.lmat_up = matrix_up;
			// Update euler angles for viewing ingame
			static.angles = vectoangles2(matrix_forward, matrix_up);
			if (static.physobj_flags & PHFLAGS_BSPMODEL)
				static.angles_x = static.angles_x*-1;
			// Static objects aren't affected by physics
			setorigin (static, self.physobj_p1.origin + self.lmat_forward*static.relative_org_x + self.lmat_left*static.relative_org_y + self.lmat_up*static.relative_org_z);
			static = static.physobj_next;
		}
		// Pushing is broken somehow :(
		// Either causes sign errors, or just acts plain weird and crazy
		// So we have to rely on pushing stuff out of solids
		hitmodel = self.physobj_hitmodel;
		if (hitmodel)
		{
			Matrix_Multiply(hitmodel.relative_forward, hitmodel.relative_left, hitmodel.relative_up, self.lmat_forward, self.lmat_left, self.lmat_up);
			hitmodel.lmat_forward = matrix_forward;
			hitmodel.lmat_left = matrix_left;
			hitmodel.lmat_up = matrix_up;
			hitmodel.angles = vectoangles2(matrix_forward, matrix_up);
			if (hitmodel.physobj_flags & PHFLAGS_BSPMODEL)
				hitmodel.angles_x = hitmodel.angles_x*-1;
			setorigin (hitmodel, self.physobj_p1.origin + self.lmat_forward*hitmodel.relative_org_x + self.lmat_left*hitmodel.relative_org_y + self.lmat_up*hitmodel.relative_org_z);
		}
		setorigin (self, self.physobj_p1.origin + self.lmat_forward*self.relative_org_x + self.lmat_left*self.relative_org_y + self.lmat_up*self.relative_org_z);
		self.velocity = self.physobj_p1.velocity; // FIXME: count average velocity
	}

	if (self.physobj_nextthink != self.physobj_lastthink)
	if (time >= self.physobj_nextthink)
	{
		self.physobj_lastthink = self.physobj_nextthink;
		self.physobj_think();
	}
/*
	// Update BSP collision model rotation and velocity
	hitmodel = self.physobj_hitmodel;
	if (hitmodel)
	{
		Matrix_Multiply(hitmodel.relative_forward, hitmodel.relative_left, hitmodel.relative_up, self.lmat_forward, self.lmat_left, self.lmat_up);
		ang = vectoangles2(matrix_forward, matrix_up);
		if (hitmodel.physobj_flags & PHFLAGS_BSPMODEL)
			ang_x = ang_x*-1;
		f = 1 / frametime;
		offset = self.physobj_p1.origin + self.lmat_forward*hitmodel.relative_org_x + self.lmat_left*hitmodel.relative_org_y + self.lmat_up*hitmodel.relative_org_z;
		hitmodel.velocity = (offset - hitmodel.origin)*f;
		anglediff = ang - hitmodel.angles;
		anglediff_x = anglediff_x - 360*floor((anglediff_x + 180) / 360);
		anglediff_y = anglediff_y - 360*floor((anglediff_y + 180) / 360);
		anglediff_z = anglediff_z - 360*floor((anglediff_z + 180) / 360);
		hitmodel.avelocity = anglediff*f;
		hitmodel.nextthink = 1000000000; // ultimahax
	}
*/
};

entity(vector org, entity basepart, entity obj) Phys_SpawnStatic =
{
	local float f;
	local vector v;
	local string s;
	local entity e;

	e = spawn();
	e.classname = "static";
	e.owner = obj;
	if (e.owner)
	{
		e.physobj_next = e.owner.physobj_staticlist;
		e.owner.physobj_staticlist = e;
	}
	if (basepart)
	{
		e.netname = basepart.netname;
		e.save_forward = e.relative_forward = basepart.relative_forward;
		e.save_left = e.relative_left = basepart.relative_left;
		e.save_up = e.relative_up = basepart.relative_up;
		e.save_org = e.relative_org = basepart.relative_org;
		e.relative_size = basepart.relative_size;
		e.mdl = basepart.mdl;
		if (basepart.mdl)
		{
			precache_model(basepart.mdl);
			setmodel(e, basepart.mdl);
			f = strlen(e.model);
			f = f - 3;
			s = substring(e.model, f, 3);
			if (s == "bsp")
				e.physobj_flags = e.physobj_flags | PHFLAGS_BSPMODEL;
			s = substring(e.model, 0, 1);
			if (s == "*") // map bmodel
				e.physobj_flags = e.physobj_flags | PHFLAGS_BSPMODEL;
		}
	}
	else
	{
		e.netname = "static";
		e.save_forward = e.relative_forward = '1 0 0';
		e.save_left = e.relative_left = '0 1 0';
		e.save_up = e.relative_up = '0 0 1';
		e.save_org = e.relative_org = org;
		e.relative_size = 0;
	}
	e.effects = EF_NOMODELFLAGS;

	e.th_die = SUB_Null;
	e.th_pain = SUB_Null;
	e.contentstransition = SUB_Null;

	setorigin(e, org);
	v_x = e.relative_size;
	v_y = v_x;
	v_z = v_x;
	setsize(e, v*-1, v);
	return e;
};

// Spawns particles for both the editor and ingame
// MOVETYPE_STEP/FL_FLY/SOLID_TRIGGER combo is used to make the particles pushable by MOVETYPE_PUSH objects, while still be able to hang in the air and be essentially non-solid
entity(vector org, entity basepart, entity obj) Phys_SpawnParticle =
{
	local float f;
	local vector v;
	local entity e;
	local string s;

	e = spawn();
	e.classname = "particle";
	e.owner = obj;
	if (e.owner)
	{
		e.owner.physobj_particles = e.owner.physobj_particles + 1;
		e.physobj_next = e.owner.physobj_particlelist;
		e.owner.physobj_particlelist = e;
		e.physobj_mass = e.owner.physobj_mass; // used as a shortcut in force calculations
	}
	if (basepart)
	{
		e.netname = basepart.netname;
		e.part_mass = basepart.part_mass;
		e.physobj_bounce = basepart.physobj_bounce;
		e.physobj_spring = basepart.physobj_spring;
		e.physobj_friction_ground = basepart.physobj_friction_ground;
		e.physobj_friction_water = basepart.physobj_friction_water;
		e.physobj_friction_air = basepart.physobj_friction_air;
		e.physobj_buoyancy = basepart.physobj_buoyancy;
		e.physobj_stiction = basepart.physobj_stiction;
		e.physobj_stepup = basepart.physobj_stepup;
		e.gravity = basepart.gravity;
		e.save_forward = e.relative_forward = basepart.relative_forward;
		e.save_left = e.relative_left = basepart.relative_left;
		e.save_up = e.relative_up = basepart.relative_up;
		e.save_org = e.relative_org = basepart.relative_org;
		e.relative_size = basepart.relative_size;
		e.mdl = basepart.mdl;
		if (basepart.mdl)
		{
			precache_model(basepart.mdl);
			setmodel(e, basepart.mdl);
			f = strlen(e.model);
			f = f - 3;
			s = substring(e.model, f, 3);
			if (s == "bsp")
				e.physobj_flags = e.physobj_flags | PHFLAGS_BSPMODEL;
			s = substring(e.model, 0, 1);
			if (s == "*") // map bmodel
				e.physobj_flags = e.physobj_flags | PHFLAGS_BSPMODEL;
		}
	}
	else
	{
		e.netname = strzone(strcat("part", ftos(e.owner.physobj_particles)));
		e.part_mass = 1;
		e.physobj_stiction = 50;
		e.physobj_friction_ground = '7.5 7.5 7.5';
		e.physobj_friction_water = '1 1 1';
		e.physobj_friction_air = '0 0 0';
		e.physobj_bounce = 1.2;
		e.physobj_stepup = 0;
		e.physobj_buoyancy = 0.2;
		e.gravity = 1;
		e.save_forward = e.relative_forward = '1 0 0';
		e.save_left = e.relative_left = '0 1 0';
		e.save_up = e.relative_up = '0 0 1';
		e.save_org = e.relative_org = org;
		e.relative_size = 0;
	}
	e.physobj_inversemass = 1 / e.part_mass;
	e.effects = EF_NOMODELFLAGS;
	e.takedamage = DAMAGE_YES;
	e.solid = SOLID_BBOX;
	e.movetype = MOVETYPE_STEP;
	e.flags = FL_FLY;

	e.th_die = SUB_Null;
	e.th_pain = SUB_Null;
	e.contentstransition = SUB_Null;

	setorigin(e, org);
	e.pushorigin = e.oldorigin = e.origin;
	v_x = e.relative_size;
	v_y = v_x;
	v_z = v_x;
	setsize(e, v*-1, v);
	return e;
};

// Spawns hitmodels for both the editor and ingame
entity(vector org, entity basepart, entity obj) Phys_SpawnHitmodel =
{
	local float f;
	//local vector v;
	local entity e;
	local string s;

	e = spawn();
	e.classname = "hitmodel";
	e.owner = obj;
	if (e.owner)
	{
		obj.physobj_hitmodel = e;
		e.physobj_mass = obj.physobj_mass;
	}
	if (basepart)
	{
		e.netname = basepart.netname;
		e.save_org = e.relative_org = basepart.relative_org;
		e.save_forward = e.relative_forward = basepart.relative_forward;
		e.save_left = e.relative_left = basepart.relative_left;
		e.save_up = e.relative_up = basepart.relative_up;
		e.mdl = basepart.mdl;
		if (basepart.mdl)
		{
			precache_model(basepart.mdl);
			setmodel(e, basepart.mdl);
			f = strlen(e.model);
			f = f - 3;
			s = substring(e.model, f, 3);
			if (s == "bsp")
				e.physobj_flags = e.physobj_flags | PHFLAGS_BSPMODEL;
			s = substring(e.model, 0, 1);
			if (s == "*") // map bmodel
				e.physobj_flags = e.physobj_flags | PHFLAGS_BSPMODEL;
		}
	}
	else
	{
		e.netname = "hitmodel";
		e.save_forward = e.relative_forward = '1 0 0';
		e.save_left = e.relative_left = '0 1 0';
		e.save_up = e.relative_up = '0 0 1';
		e.save_org = e.relative_org = org;
	}
	e.takedamage = DAMAGE_YES;
	e.solid = SOLID_BSP;
	e.effects = EF_NOMODELFLAGS;
	e.model = ""; // better way to nosend than EF_NODRAW

	e.th_die = SUB_Null;
	e.th_pain = SUB_Null;
	e.contentstransition = SUB_Null;

	setorigin(e, org);
	return e;
};

entity(entity basepart) Phys_ObjectSpawn =
{
	local entity e;
	e = spawn();
	e.classname = "physics_object";
	e.netname = basepart.netname;
	e.filename = basepart.filename;
	e.physobj_mass = basepart.physobj_mass;
	e.think = Phys_ObjectThink;
	e.nextthink = time;
	e.contentstransition = SUB_Null;
	e.physobj_think = SUB_Null;
	e.physobj_impactevent = SUB_Null;
	return e;
};

void(entity obj) Phys_ObjectRemove =
{
	local entity e, next;
	if (!obj)
		return;
	e = obj.physobj_particlelist;
	while (e)
	{
		next = e.physobj_next;
		remove(e);
		e = next;
	}
	e = obj.physobj_sticklist;
	while (e)
	{
		next = e.physobj_next;
		remove(e);
		e = next;
	}
	e = obj.physobj_hitmodel;
	if (e)
		remove(e);
	e = obj.physobj_staticlist;
	while (e)
	{
		next = e.physobj_next;
		remove(e);
		e = next;
	}
	e = object_list;
	if (e == obj)
		object_list = obj.object_next;
	else
	{
		while (e)
		{
			if (e.object_next == obj)
			{
				e.object_next = obj.object_next;
				break;
			}
			e = e.object_next;
		}
	}
	remove(obj);
};

void(entity stick, entity object) Phys_ObjectRemoveStick =
{
	local entity e;

	e = object.physobj_sticklist;
	if (e == stick)
		object.physobj_sticklist = stick.physobj_next;
	else
	{
		while (e)
		{
			if (e.physobj_next == stick)
			{
				e.physobj_next = stick.physobj_next;
				break;
			}
			e = e.physobj_next;
		}
	}
	remove(stick);
};

void(entity part, entity object) Phys_ObjectRemoveParticle =
{
	local entity e;

	e = object.physobj_sticklist;
	while (e)
	{
		if (e.physobj_p1 == part || e.physobj_p2 == part)
			Phys_ObjectRemoveStick(e, object);
		e = e.physobj_next;
	}
	e = object.physobj_particlelist;
	if (e == part)
		object.physobj_particlelist = part.physobj_next;
	else
	{
		while (e)
		{
			if (e.physobj_next == part)
			{
				e.physobj_next = part.physobj_next;
				break;
			}
			e = e.physobj_next;
		}
	}
	remove(part);
	object.physobj_particles = object.physobj_particles - 1;
};

entity(entity p1, entity p2, entity obj) Phys_ObjectAddStick =
{
	local entity e;

	e = spawn();
	e.classname = "stick";
	e.owner = obj;
	if (e.owner)
	{
		e.physobj_next = e.owner.physobj_sticklist;
		e.owner.physobj_sticklist = e;
	}
	e.physobj_p1 = p1;
	e.physobj_p2 = p2;
	e.stick_preferredlength = vlen(p2.relative_org - p1.relative_org);
	// the following is used by the physics to prevent sign errors
	if (p1.stick_preferredlength <= 0)
		p1.stick_preferredlength = 99999999;
	p1.stick_preferredlength = min(p1.stick_preferredlength, e.stick_preferredlength*0.5);
	if (p2.stick_preferredlength <= 0)
		p2.stick_preferredlength = 99999999;
	p2.stick_preferredlength = min(p2.stick_preferredlength, e.stick_preferredlength*0.5);
	return e;
};

entity(vector org, entity object) Phys_AddParticleToObject =
{
	local vector save_rel;
	local entity e, stick, part, end;

	part = object.physobj_particlelist;
	while(part)
	{
		end = part;
		part = part.physobj_next;
	}

	e = Phys_SpawnParticle(org, world, world);
	e.owner = object.physobj_hitmodel;
	object.physobj_particles = object.physobj_particles + 1;
	end.physobj_next = e;

	stick = object.physobj_sticklist;
	while(stick)
	{
		end = stick;
		stick = stick.physobj_next;
	}
	part = object.physobj_particlelist;
	while (part && part != e)
	{
		save_rel = part.relative_org;
		part.relative_org = part.origin;
		stick = Phys_ObjectAddStick(e, part, world);
		part.relative_org = save_rel;
		stick.owner = object;
		end.physobj_next = stick;
		end = stick;
		part = part.physobj_next;
	}
	return e;
};

void() Phys_SpawnSticks =
{
	local float f, total;
	local entity part1, part2;

	total = 0;
	part1 = physobj_spawning.physobj_particlelist;
	while (part1)
	{
		total = total + 1;
		part1 = part1.physobj_next;
	}
	part1 = physobj_spawning.physobj_particlelist;
	while (part1)
	{
		part2 = part1;
		total = total - 1;
		f = 0;
		while (f < total)
		{
			part2 = part2.physobj_next;
			Phys_ObjectAddStick(part1, part2, physobj_spawning);
			f = f + 1;
		}
		part1 = part1.physobj_next;
	}
}

// Dynamicly adds an object into the object list
// Automaticly spawns particles and sticks based on a bmodel
// NOTE: works only on brushes, beware of model based submodels in Q3BSP
entity(entity base, entity hitbase, entity statbase) Dynamic_BModelObject =
{
	local float numpoint, surf;
	local entity obj, part, e, e2;
	local vector org;

	obj = physobj_spawning = spawn();
	obj.object_next = object_list;
	object_list = obj;
	obj.netname = base.netname;
	obj.physobj_mass = base.physobj_mass;

	surf = 0;
	numpoint = getsurfacenumpoints(base, surf);
	while (numpoint)
	{
		surf = surf + 1;
		while (numpoint)
		{
			org = getsurfacepoint(base, surf, numpoint);
			if (org != base.origin) // hax, submodels for some reason have a vertex at '0 0 0'
			{
				org = org-base.relative_org;
				e = Phys_SpawnParticle(org, world, obj);
				e.physobj_stiction = base.physobj_stiction;
				e.physobj_friction_ground = base.physobj_friction_ground;
				e.physobj_friction_water = base.physobj_friction_water;
				e.physobj_friction_air = base.physobj_friction_air;
				e.physobj_bounce = base.physobj_bounce;
				e.physobj_buoyancy = base.physobj_buoyancy;
				e.gravity = base.gravity;
			}
			numpoint = numpoint - 1;
		}
		numpoint = getsurfacenumpoints(base, surf);
	}
	// remove duplicates
	part = obj.physobj_particlelist;
	while (part)
	{
		e = obj.physobj_particlelist;
		while (e)
		{
			e2 = e;
			e = e.physobj_next;
			if (e2 != part)
			if (e2.origin == part.origin)
				Phys_ObjectRemoveParticle(e2, obj);
		}
		part = part.physobj_next;
	}
	if (hitbase)
	{
		e = Phys_SpawnHitmodel(hitbase.origin - hitbase.relative_org, world, obj);
		e.mdl = hitbase.mdl;
	}
	if (statbase)
	{
		e = Phys_SpawnStatic(statbase.origin - statbase.relative_org, world, obj);
		e.mdl = statbase.mdl;
	}
	Phys_SpawnSticks();
	return obj;
};

// Used for creating the physics objects ingame
entity(entity obj, vector org, vector forward, vector left, vector up, vector toss, float randvel) Phys_ObjectCreate =
{
	local float f;
	local entity e, part;
	local vector org1, org2, org3, v;

	physobj_spawning = Phys_ObjectSpawn(obj);

	e = obj.physobj_particlelist;
	while(e)
	{
		part = Phys_SpawnParticle(org + up*e.relative_org_z + left*e.relative_org_y + forward*e.relative_org_x, e, physobj_spawning);
		setvelocity(part, toss + randomvec()*randvel);
		//part.velocity = toss + randomvec()*randvel;
		e.enemy = part; // used for easier stick spawning
		e = e.physobj_next;
	}
	e = obj.physobj_sticklist;
	while (e)
	{
		Phys_ObjectAddStick(e.physobj_p1.enemy, e.physobj_p2.enemy, physobj_spawning);
		e = e.physobj_next;
	}
	e = obj.physobj_hitmodel;
	if (e)
		Phys_SpawnHitmodel(org + up*e.relative_org_z + left*e.relative_org_y + forward*e.relative_org_x, e, physobj_spawning);
	e = obj.physobj_staticlist;
	while(e)
	{
		Phys_SpawnStatic(org + up*e.relative_org_z + left*e.relative_org_y + forward*e.relative_org_x, e, physobj_spawning);
		e = e.physobj_next;
	}

	// Assign the first three particles, used for origin and orientation of the object ingame
	physobj_spawning.physobj_p1 = physobj_spawning.physobj_particlelist;
	physobj_spawning.physobj_p2 = physobj_spawning.physobj_p1.physobj_next;
	physobj_spawning.physobj_p3 = physobj_spawning.physobj_p2.physobj_next;

	// Recalculate relative_org for use ingame
	e = physobj_spawning.physobj_hitmodel;
	if (e)
	{
		v = e.origin - physobj_spawning.physobj_p1.origin;
		e.relative_org_z = up*v;
		e.relative_org_y = left*v;
		e.relative_org_x = forward*v;
	}
	// Also make particles and static objects owned by the hitmodel, to ignore collisions
	e = physobj_spawning.physobj_staticlist;
	while (e)
	{
		e.realowner = e.owner;
		e.owner = physobj_spawning.physobj_hitmodel;
		v = e.origin - physobj_spawning.physobj_p1.origin;
		e.relative_org_z = up*v;
		e.relative_org_y = left*v;
		e.relative_org_x = forward*v;
		e = e.physobj_next;
	}
	e = physobj_spawning.physobj_particlelist;
	while(e)
	{
		e.realowner = e.owner;
		e.owner = physobj_spawning.physobj_hitmodel;
		e = e.physobj_next;
	}
	// let's save the center of mass for this object
	v = '0 0 0';
	e = physobj_spawning.physobj_particlelist;
	while(e)
	{
		f = f + e.part_mass;
		v = v + e.origin*e.part_mass;
		e = e.physobj_next;
	}
	v = v*(1/f);
	v = v-physobj_spawning.physobj_p1.origin;
	physobj_spawning.relative_org_z = up*v;
	physobj_spawning.relative_org_y = left*v;
	physobj_spawning.relative_org_x = forward*v;

	// LordHavoc: Calculate the matrix of the first three particles
	// this matrix is what the 3 particles produced in the editor, and we need
	// to exactly undo this matrix when generating the ingame orientations
	org1 = physobj_spawning.physobj_p1.relative_org;
	org2 = physobj_spawning.physobj_p2.relative_org;
	org3 = physobj_spawning.physobj_p3.relative_org;
	physobj_spawning.objbase_forward = normalize(org2-org1);
	physobj_spawning.objbase_left = org3-org1;
	physobj_spawning.objbase_up = normalize(crossproduct(physobj_spawning.objbase_forward, physobj_spawning.objbase_left));
	physobj_spawning.objbase_left = normalize(crossproduct(physobj_spawning.objbase_forward, physobj_spawning.objbase_up));

	return physobj_spawning;
};
