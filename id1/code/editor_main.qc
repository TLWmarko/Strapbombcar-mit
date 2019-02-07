float(float f) Snap2Grid =
{
	float rh, rl, r, rval;

	if (f == 0)
		return 0;

	if (f < 0)
	{
		rval = -1;
		f = f*-1;
	}
	else
		rval = 1;

	while(rh < f)
		rh = rh + self.pe_grid;
	rl = rh - self.pe_grid;
	r = (rh-rl)*0.5;
	f = f - rl;
	if (f < r)
		return rl*rval;
	else
		return rh*rval;
};

void() Editor_SetupPhysObjEditor =
{
	if (self.clientstate == PHYSOBJEDITOR)
	{
		stuffcmd(self, "-strafe\n");
		Phys_ObjectRemove(self.pe_object);
		self.pe_object = self.pe_part = world;
		PutClientInServer();
		if (self.pe_org1 && self.pe_org2)
		{
			remove(self.pe_org1);
			remove(self.pe_org2);
			self.pe_org1 = self.pe_org2 = world;
		}
		centerprint(self, "\n");
	}
	else
	{
		if (!self.pe_org1 || !self.pe_org2)
		{
			self.pe_org1 = spawn();
			setmodel(self.pe_org1, "progs/org.mdl");
			setorigin(self.pe_org1, '0 0 0');
			self.pe_org1.alpha = 0.5;
			self.pe_org2 = spawn();
			setmodel(self.pe_org2, "progs/org2.mdl");
			setorigin(self.pe_org2, '0 0 0');
			self.pe_org2.alpha = 0.5;
		}
		self.inmenu = 1; // initialize the menu

		self.movetype = MOVETYPE_NONE;
		self.pe_zoom = 150;
		self.view_ofs = '0 0 0';
		makevectors(self.v_angle);
		setorigin(self, v_forward*-1*self.pe_zoom);

		self.clientstate = PHYSOBJEDITOR;
	}
	Object_RemoveAllFileObjects();
	Object_LoadAllObjects();
};

void() Editor_SwitchAxis =
{
	if (self.clientstate != PHYSOBJEDITOR)
		return;

	if (self.pe_axis == '1 0 0')
		self.pe_axis = '0 1 0';
	else if (self.pe_axis == '0 1 0')
		self.pe_axis = '0 0 1';
	else
		self.pe_axis = '1 0 0';
};

void(entity part) Editor_SwitchPart =
{
	local entity temp;

	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (self.inmenu)
		return;

	temp = self.pe_part;
	if (part)
		self.pe_part = part;
	else
		self.pe_part = self.pe_part.physobj_next;
	if (!self.pe_part)
	{
		if (temp.classname == "particle")
		{
			if (self.pe_object.physobj_hitmodel)
				self.pe_part = self.pe_object.physobj_hitmodel;
			else if (self.pe_object.physobj_staticlist)
				self.pe_part = self.pe_object.physobj_staticlist;
			else
				self.pe_part = self.pe_object.physobj_particlelist;
		}
		else if (temp.classname == "hitmodel")
		{
			if (self.pe_object.physobj_staticlist)
				self.pe_part = self.pe_object.physobj_staticlist;
			else if (self.pe_object.physobj_particlelist)
				self.pe_part = self.pe_object.physobj_particlelist;
			else
				self.pe_part = self.pe_object.physobj_hitmodel;
		}
		else if (temp.classname == "static")
		{
			if (self.pe_object.physobj_particlelist)
				self.pe_part = self.pe_object.physobj_particlelist;
			else if (self.pe_object.physobj_hitmodel)
				self.pe_part = self.pe_object.physobj_hitmodel;
			else
				self.pe_part = self.pe_object.physobj_staticlist;
		}
		else
		{
			if (self.pe_object.physobj_particlelist)
				self.pe_part = self.pe_object.physobj_particlelist;
			else if (self.pe_object.physobj_hitmodel)
				self.pe_part = self.pe_object.physobj_hitmodel;
			else
				self.pe_part = self.pe_object.physobj_staticlist;
		}
	}
	if (self.pe_part)
		self.pe_part.colormod = '1 1 1';
	if (temp)
	if (temp != self.pe_part)
		temp.colormod = '2 2 2';
	self.pe_size = self.pe_part.relative_size;
	self.pe_move = self.pe_part.origin;
	self.pe_rot = self.pe_part.pe_rot;
	self.pe_org1.angles = self.pe_org2.angles = self.pe_part.angles;
	if (self.pe_part.physobj_flags & PHFLAGS_BSPMODEL)
		self.pe_org1.angles_x = self.pe_org2.angles_x = self.pe_org1.angles_x*-1;
};

void(entity targ, string smdl) Editor_ChangeModel =
{
	local float f, file;
	local string s;
	local vector v;

	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (self.inmenu)
		return;

	if (targ)
	{
		v_x = v_y = v_z = targ.relative_size;
		if (smdl == "" || smdl == "none")
		{
			targ.mdl = "";
			if (targ.relative_size)
			{
				targ.modelindex = modelindex_box;
				targ.scale = targ.relative_size*0.1;
			}
			else
			{
				targ.modelindex = modelindex_point;
				targ.scale = 0.25;
			}
			setsize(targ, v*-1, v);
			return;
		}
		file = search_begin(smdl, TRUE, FALSE);
		if (file != -1)
		{
			precache_model(smdl);
			setmodel(targ, smdl);
			targ.mdl = targ.model;
			if (targ.classname != "hitmodel")
				setsize(targ, v*-1, v);
			f = strlen(smdl);
			f = f - 3;
			s = substring(smdl, f, 3);
			if (s == "bsp")
				targ.physobj_flags = targ.physobj_flags | PHFLAGS_BSPMODEL;
			else
				targ.physobj_flags = targ.physobj_flags - (targ.physobj_flags & PHFLAGS_BSPMODEL);
			targ.scale = 1;
			search_end(file);
		}
		else
			print("Could not find model\n");
	}
};

void(entity targ, string s) Editor_ChangeName =
{
	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (self.inmenu)
		return;

	if (targ)
		targ.netname = s;
};

void(float sajz) Editor_ResizePart =
{
	local entity e;
	local vector v;

	if (self.inmenu)
		return;

	if (self.clientstate == PHYSOBJEDITOR)
	if (self.pe_part)
	{
		if (self.pe_part.classname == "hitmodel")
		{
			print("Cannot resize hitmodels\n");
			return;
		}
		self.pe_part.relative_size = sajz;
		v_x = v_y = v_z = sajz;
		setsize(self.pe_part, v*-1, v);
		if (!self.pe_part.mdl)
		{
			if (self.pe_part.relative_size)
			{
				self.pe_part.modelindex = modelindex_box;
				self.pe_part.scale = self.pe_part.relative_size*0.1;
			}
			else
			{
				self.pe_part.modelindex = modelindex_point;
				self.pe_part.scale = 0.25;
			}
		}
		else
			self.pe_part.scale = 1;
		self.pe_size = self.pe_part.relative_size;
	}
	if (!self.clientstate)
	if (object_current)
	{
		e = object_current.physobj_particlelist;
		while (e)
		{
			e.relative_size = sajz;
			e = e.physobj_next;
		}
	}
};

void() Editor_MovePart =
{
	local vector org;

	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (self.inmenu)
		return;

	if (self.pe_part)
	{
		org = self.pe_part.origin;
		if (self.pe_axis_x)
		{
			self.pe_move_x = self.pe_move_x + self.movement_x * 0.01;
			org_x = Snap2Grid(self.pe_move_x);
		}
		else if (self.pe_axis_y)
		{
			self.pe_move_y = self.pe_move_y + self.movement_x * 0.01;
			org_y = Snap2Grid(self.pe_move_y);
		}
		else if (self.pe_axis_z)
		{
			self.pe_move_z = self.pe_move_z + self.movement_x * 0.01;
			org_z = Snap2Grid(self.pe_move_z);
		}
		setorigin(self.pe_part, org);
		self.pe_part.relative_org = org;
	}
};

// Rotates a matrix using Rodriguez vector technique
// NOTE: try and figure out a faster way to do it
void(entity head, vector axis, float ang) Editor_RotatePart_DoRotation =
{
	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (!ang)
		return;

	// Rotate given amount around given axis
	matrix_forward = '1 0 0';
	matrix_left    = '0 1 0';
	matrix_up      = '0 0 1';
	Matrix_RotateByAxisAngle(axis, ang);
	head.relative_forward = normalize(matrix_forward);
	head.relative_left = normalize(matrix_left);
	head.relative_up = normalize(matrix_up);
};

void() Editor_RotatePart =
{
	local float f;

	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (self.inmenu)
		return;

	if (self.pe_part)
	{
		if (self.pe_axis_x)
		{
			self.pe_rot_x = self.pe_rot_x + self.movement_x * 0.02;
			f = Snap2Grid(self.pe_rot_x);
			if (f)
			{
				Editor_RotatePart_DoRotation(self.pe_part, self.pe_part.relative_forward, f);
				self.pe_part.pe_rot_x = f;
			}
		}
		else if (self.pe_axis_y)
		{
			self.pe_rot_y = self.pe_rot_y + self.movement_x * 0.02;
			f = Snap2Grid(self.pe_rot_y);
			if (f)
			{
				Editor_RotatePart_DoRotation(self.pe_part, self.pe_part.relative_left, f);
				self.pe_part.pe_rot_y = f;
			}
		}
		else if (self.pe_axis_z)
		{
			self.pe_rot_z = self.pe_rot_z + self.movement_x * 0.02;
			f = Snap2Grid(self.pe_rot_z);
			if (f)
			{
				Editor_RotatePart_DoRotation(self.pe_part, self.pe_part.relative_up, f);
				self.pe_part.pe_rot_z = f;
			}
		}
	}
};

entity(string type, vector org, entity basepart, entity obj) Editor_SpawnPart =
{
	local float modelindex_save;
	local vector v;
	local entity part;

	if (self.clientstate != PHYSOBJEDITOR)
		return world;

	if (type == "particle")
		part = Phys_SpawnParticle(org, basepart, obj);
	else if (type == "hitmodel")
	{
		if (self.pe_object.physobj_hitmodel)
		{
			print("ERROR: Object already has a hitmodel\n");
			return world;
		}
		part = Phys_SpawnHitmodel(org, basepart, obj);
	}
	else if (type == "static")
		part = Phys_SpawnStatic(org, basepart, obj);
	modelindex_save = part.modelindex;
	setmodel (part, "progs/partbox.mdl");
	modelindex_box = part.modelindex;
	setmodel (part, "progs/point.spr");
	modelindex_point = part.modelindex;
	if (!modelindex_save)
	{
		part.scale = 0.25;
		part.effects = EF_NODEPTHTEST;
		if (part.relative_size)
		{
			part.scale = part.relative_size*0.1;
			part.modelindex = modelindex_box;
		}
	}
	else
		setmodel(part, part.mdl);
	if (type != "hitmodel")
	{
		v_x = v_y = v_z = part.relative_size;
		setsize(part, v*-1, v);
	}
	return part;
};

void(entity basebox) Editor_MakeBox =
{
	local vector org;

	if (self.clientstate != PHYSOBJEDITOR)
		return;
	if (self.inmenu)
		return;

	org = basebox.mins;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.mins;
	org_x = basebox.maxs_x;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.mins;
	org_y = basebox.maxs_y;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.mins;
	org_z = basebox.maxs_z;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.mins;
	org_x = basebox.maxs_x;
	org_y = basebox.maxs_y;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.mins;
	org_x = basebox.maxs_x;
	org_z = basebox.maxs_z;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.mins;
	org_y = basebox.maxs_y;
	org_z = basebox.maxs_z;
	Editor_SpawnPart("particle", org, world, self.pe_object);
	org = basebox.maxs;
	Editor_SpawnPart("particle", org, world, self.pe_object);
};

void() Editor_FixDefaultValues =
{
	local entity e, obj;

	if (self.inmenu)
		return;

	if (self.clientstate == PHYSOBJEDITOR)
		obj = self.pe_object;
	else
		obj = object_current;
	if (!obj)
		return;

	if (!obj.physobj_mass)
		obj.physobj_mass = 50;

	e = obj.physobj_particlelist;
	while (e)
	{
		if (!e.part_mass)
			e.part_mass = 1;
		if (!e.physobj_stiction)
			e.physobj_stiction = 50;
		if (!e.physobj_friction_ground)
			e.physobj_friction_ground = '7.5 7.5 7.5';
		if (!e.physobj_friction_water)
			e.physobj_friction_water = '1 1 1';
		if (!e.physobj_friction_air)
			e.physobj_friction_air = '0 0 0';
		if (!e.physobj_bounce)
			e.physobj_bounce = 1.2;
		if (!e.physobj_buoyancy)
			e.physobj_buoyancy = 0.2;
		if (!e.gravity)
			e.gravity = 1;
		e = e.physobj_next;
	}
};

void(string att, float val) Editor_SetPartAttribute =
{
	local float loopall;
	local entity e;

	if (self.inmenu)
		return;

	if (self.clientstate == PHYSOBJEDITOR)
		e = self.pe_part;
	else
	{
		e = object_current.physobj_particlelist;
		loopall = TRUE;
	}
	if (e.classname != "particle")
		return;

	while (e)
	{
		if (att == "mass")
			e.part_mass = val;
		else if (att == "bounce")
			e.physobj_bounce = val;
		else if (att == "stepup")
			e.physobj_stepup = val;
		else if (att == "stiction")
			e.physobj_stiction = val;
		else if (att == "friction_ground")
			e.physobj_friction_ground = '1 1 1'*val;
		else if (att == "spring_x")
			e.physobj_spring_x = val;
		else if (att == "spring_y")
			e.physobj_spring_y = val;
		else if (att == "spring_z")
			e.physobj_spring_z = val;
		else if (att == "friction_ground_x")
			e.physobj_friction_ground_x = val;
		else if (att == "friction_ground_y")
			e.physobj_friction_ground_y = val;
		else if (att == "friction_ground_z")
			e.physobj_friction_ground_z = val;
		else if (att == "friction_water")
			e.physobj_friction_water = '1 1 1'*val;
		else if (att == "friction_water_x")
			e.physobj_friction_water_x = val;
		else if (att == "friction_water_y")
			e.physobj_friction_water_y = val;
		else if (att == "friction_water_z")
			e.physobj_friction_water_z = val;
		else if (att == "friction_air")
			e.physobj_friction_air = '1 1 1'*val;
		else if (att == "friction_air_x")
			e.physobj_friction_air_x = val;
		else if (att == "friction_air_y")
			e.physobj_friction_air_y = val;
		else if (att == "friction_air_z")
			e.physobj_friction_air_z = val;
		else if (att == "buoyancy")
			e.physobj_buoyancy = val;
		else if (att == "gravity")
			e.gravity = val;
		if (loopall)
			e = e.physobj_next;
	}
};

void (string att, float val) Editor_SetObjectAttribute =
{
	local entity e;

	if (self.inmenu)
		return;

	if (self.clientstate == PHYSOBJEDITOR)
		e = self.pe_object;
	else
		e = object_current;
	if (!e)
		return;
	if (att == "mass")
		e.physobj_mass = val;
};

void() Editor_ObjectThink =
{
	local entity e;

	self.nextthink = time;

	e = self.physobj_particlelist;
	while (e)
	{
		e.angles = vectoangles2(e.relative_forward, e.relative_up);
		if (e.physobj_flags & PHFLAGS_BSPMODEL)
			e.angles_x = e.angles_x*-1;
		e = e.physobj_next;
	}
	e = self.physobj_hitmodel;
	if (e)
	{
		e.angles = vectoangles2(e.relative_forward, e.relative_up);
		if (e.physobj_flags & PHFLAGS_BSPMODEL)
			e.angles_x = e.angles_x*-1;
	}
	e = self.physobj_staticlist;
	while (e)
	{
		e.angles = vectoangles2(e.relative_forward, e.relative_up);
		if (e.physobj_flags & PHFLAGS_BSPMODEL)
			e.angles_x = e.angles_x*-1;
		e = e.physobj_next;
	}
};

void(entity targ) Editor_SpawnObject =
{
	local entity part, temp;

	self.pe_object = self.pe_part = world;
	physobj_spawning = Phys_ObjectSpawn(targ);
	physobj_spawning.think = Editor_ObjectThink;
	self.pe_object = physobj_spawning;
	physobj_spawning.owner = self;
	part = targ.physobj_particlelist;
	while (part)
	{
		temp = Editor_SpawnPart("particle", part.relative_org, part, physobj_spawning);
		if (temp)
			temp.colormod = '2 2 2';
		part = part.physobj_next;
	}
	part = targ.physobj_hitmodel;
	if (part)
	{
		temp = Editor_SpawnPart("hitmodel", part.relative_org, part, physobj_spawning);
		if (temp)
			temp.colormod = '2 2 2';
	}
	part = targ.physobj_staticlist;
	while (part)
	{
		temp = Editor_SpawnPart("static", part.relative_org, part, physobj_spawning);
		if (temp)
			temp.colormod = '2 2 2';
		part = part.physobj_next;
	}
	Editor_SwitchPart(world);
};

void() Editor_Input =
{
	if (self.button4) // holding down ctrl
	{
		if (self.impulse == WHEELUP)
			self.pe_grid = max(1, self.pe_grid*2);
		else if (self.impulse == WHEELDOWN)
			self.pe_grid = floor(self.pe_grid/2);
		else if (self.button0 && !self.button2)
		{
			stuffcmd(self, "+strafe\n");
			Editor_MovePart();
			self.pe_org1.angles = self.pe_org2.angles = '0 0 0';
		}
		else if (self.button2 && !self.button0)
		{
			stuffcmd(self, "+strafe\n");
			Editor_RotatePart();
			self.pe_org1.angles = self.pe_org2.angles = self.pe_part.angles;
			if (self.pe_part.physobj_flags & PHFLAGS_BSPMODEL)
				self.pe_org1.angles_x = self.pe_org2.angles_x = self.pe_part.angles_x*-1;
		}
		else
			stuffcmd(self, "-strafe\n");
	}
	else
	{
        if (self.mousebuttondown)
        {
            if (self.button0 || self.button2)
                return;
            else
                self.mousebuttondown = FALSE;
        }
        if (self.button0 || self.button2)
            self.mousebuttondown = TRUE;
		stuffcmd(self, "-strafe\n");
		if (self.impulse == WHEELUP)
			self.pe_zoom = max(20, self.pe_zoom - 10);
		else if (self.impulse == WHEELDOWN)
			self.pe_zoom = self.pe_zoom + 10;
		else if (self.button0 && !self.button2)
			Editor_SwitchPart(world);
		else if (self.button2 && !self.button0)
			Editor_SwitchAxis();
	}
};

void() Editor_Refresh =
{
	Editor_Input();
	setorigin(self.pe_org1, self.pe_part.relative_org);
	setorigin(self.pe_org2, self.pe_part.relative_org);
	makevectors(self.v_angle);
	setorigin(self, v_forward*-1*self.pe_zoom); // insane awesome camera action
};

void() Editor_Commands =
{
	local string c;

	c = argv(1);
	if (c == "particle")
		Editor_SwitchPart(Editor_SpawnPart("particle", '0 0 0', world, self.pe_object));
	else if (c == "hitmodel")
		Editor_SwitchPart(Editor_SpawnPart("hitmodel", '0 0 0', world, self.pe_object));
	else if (c == "static")
		Editor_SwitchPart(Editor_SpawnPart("static", '0 0 0', world, self.pe_object));
	else if (c == "model")
		Editor_ChangeModel(self.pe_part, argv(2));
	else if (c == "makebox")
		Editor_MakeBox(self.pe_part);
	else if (c == "objectname")
		Editor_ChangeName(self.pe_object, strzone(argv(2)));
	else if (c == "objectmass")
		Editor_SetObjectAttribute("mass", stof(argv(2)));
	else if (c == "name")
		Editor_ChangeName(self.pe_part, strzone(argv(2)));
	else if (c == "size")
		Editor_ResizePart(stof(argv(2)));
	else if (c == "mass")
		Editor_SetPartAttribute("mass", stof(argv(2)));
	else if (c == "bounce")
		Editor_SetPartAttribute("bounce", stof(argv(2)));
	else if (c == "stepup")
		Editor_SetPartAttribute("stepup", stof(argv(2)));
	else if (c == "spring_x")
		Editor_SetPartAttribute("spring_x", stof(argv(2)));
	else if (c == "spring_y")
		Editor_SetPartAttribute("spring_y", stof(argv(2)));
	else if (c == "spring_z")
		Editor_SetPartAttribute("spring_z", stof(argv(2)));
	else if (c == "friction_ground")
		Editor_SetPartAttribute("friction_ground", stof(argv(2)));
	else if (c == "friction_ground_x")
		Editor_SetPartAttribute("friction_ground_x", stof(argv(2)));
	else if (c == "friction_ground_y")
		Editor_SetPartAttribute("friction_ground_y", stof(argv(2)));
	else if (c == "friction_ground_z")
		Editor_SetPartAttribute("friction_ground_z", stof(argv(2)));
	else if (c == "friction_water")
		Editor_SetPartAttribute("friction_water", stof(argv(2)));
	else if (c == "friction_water_x")
		Editor_SetPartAttribute("friction_water_x", stof(argv(2)));
	else if (c == "friction_water_y")
		Editor_SetPartAttribute("friction_water_y", stof(argv(2)));
	else if (c == "friction_water_z")
		Editor_SetPartAttribute("friction_water_z", stof(argv(2)));
	else if (c == "friction_air")
		Editor_SetPartAttribute("friction_air", stof(argv(2)));
	else if (c == "friction_air_x")
		Editor_SetPartAttribute("friction_air_x", stof(argv(2)));
	else if (c == "friction_air_y")
		Editor_SetPartAttribute("friction_air_y", stof(argv(2)));
	else if (c == "friction_air_z")
		Editor_SetPartAttribute("friction_air_z", stof(argv(2)));
	else if (c == "buoyancy")
		Editor_SetPartAttribute("buoyancy", stof(argv(2)));
	else if (c == "stiction")
		Editor_SetPartAttribute("stiction", stof(argv(2)));
	else if (c == "gravity")
		Editor_SetPartAttribute("gravity", stof(argv(2)));
	else if (c == "fixdefaults")
		Editor_FixDefaultValues();
	else if (c == "grid")
		self.pe_grid = stof(argv(2));
	else if (c == "save")
	{
		if (self.clientstate != PHYSOBJEDITOR)
			Object_Save(argv(2), object_current);
		else
			Object_Save(argv(2), self.pe_object);
	}
};

void() Editor_PickObject =
{
	object_current = object_current.object_next;
	if (!object_current)
		object_current = object_list;
};

// Editor Menu and display
void() Editor_Menu =
{
	local string s, s2;

	if (self.menu_time < time)
	{
		self.menu_time = time; // used to be time + 0.05, but this is to make sure impulse handling is responsive :(
		if (self.inmenu == 1)
		{
			if (!self.pe_object)
			{
				Editor_PickObject();
				self.inmenu = 0;
				Editor_SpawnObject(object_current);
				self.inmenu = 1;
			}
			s = strcat("1. [NEW OBJECT]\n", "2. [EDIT THIS OBJECT] (");
			s = strcat(s, self.pe_object.filename);
			s = strcat(s, ")\n");
			s = strcat(s, "3. [NEXT OBJECT]\n");
			// experimental impulse handling
			if (self.impulse == 1)
			{
				Phys_ObjectRemove(self.pe_object);
				Editor_SpawnObject(world);
				self.inmenu = 0;
				self.menu_time = 0;
			}
			else if (self.impulse == 2)
			{
				self.inmenu = 0;
				self.menu_time = 0;
			}
			else if (self.impulse == 3)
			{
				Phys_ObjectRemove(self.pe_object);
				Editor_PickObject();
				Editor_SpawnObject(object_current);
				self.menu_time = 0;
			}
		}
		else
		{
			s = strcat("Object ", self.pe_object.filename);
			s = strcat(s, "\nGrid: ");
			s = strcat(s, ftos(self.pe_grid));
			if (self.pe_axis_x)
				s2 = "^4X ^7y z";
			else if (self.pe_axis_y)
				s2 = "x ^3Y ^7z";
			else if (self.pe_axis_z)
				s2 = "x y ^1Z^7";
			s = strcat(s, "\nAxis: ");
			s = strcat(s, s2);
			s = strcat(s, "\nPart: ");
			s = strcat(s, self.pe_part.netname);
			if (self.button4)
			{
				if (self.button0 && !self.button2)
				{
					s = strcat(s, "\nPart Origin:\nX ");
					s = strcat(s, ftos(self.pe_part.origin_x));
					s = strcat(s, "\nY ");
					s = strcat(s, ftos(self.pe_part.origin_y));
					s = strcat(s, "\nZ ");
					s = strcat(s, ftos(self.pe_part.origin_z));
					
				}
				else if (self.button2 && !self.button0)
				{
					s = strcat(s, "\nPart Angle:\nX ");
					s = strcat(s, ftos(self.pe_part.pe_rot_x));
					s = strcat(s, "\nY ");
					s = strcat(s, ftos(self.pe_part.pe_rot_y));
					s = strcat(s, "\nZ ");
					s = strcat(s, ftos(self.pe_part.pe_rot_z));
					
				}
			}
		}
		centerprint(self, s);
	}
};