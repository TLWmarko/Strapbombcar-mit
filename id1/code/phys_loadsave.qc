// makerigid: spawns full length sticks between all particles in the object (mainly used by v1 files)
void(string sfilename, entity obj) Object_Save =
{
	local float file;
	local float f;
	local string s;
	local entity part;

	if (sfilename == "")
		sfilename = obj.filename;
	if (sfilename == "")
	{
		print("ERROR: no filename supplied\n");
		return;
	}
	if (!obj)
	{
		print("ERROR: no object to save\n");
		return;
	}

	f = strlen(sfilename);
	f = f - 4;
	s = substring(sfilename, f, 4);
	if (s != ".ubj")
		sfilename = strcat(sfilename, ".ubj");
	file = fopen(sfilename, FILE_WRITE);
	if (file >= 0)
	{
		fputs(file, "object ");
		fputs(file, obj.netname);
		fputs(file, " 0\n");
		if (obj.physobj_mass)
		{
			fputs(file, "mass ");
			fputs(file, ftos(obj.physobj_mass));
			fputs(file, "\n");
		}
		part = obj.physobj_particlelist;
		if (part)
		{
			while (part)
			{
				fputs(file, "particle ");
				fputs(file, part.netname);
				fputs(file, " 1\n");
				if (vlen(part.relative_org))
				{
					fputs(file, "origin ");
					fputs(file, ftos(part.relative_org_x));
					fputs(file, " ");
					fputs(file, ftos(part.relative_org_y));
					fputs(file, " ");
					fputs(file, ftos(part.relative_org_z));
					fputs(file, "\n");
				}
				fputs(file, "matrix ");
				fputs(file, ftos(part.relative_forward_x));
				fputs(file, " ");
				fputs(file, ftos(part.relative_forward_y));
				fputs(file, " ");
				fputs(file, ftos(part.relative_forward_z));
				fputs(file, " ");
				fputs(file, ftos(part.relative_left_x));
				fputs(file, " ");
				fputs(file, ftos(part.relative_left_y));
				fputs(file, " ");
				fputs(file, ftos(part.relative_left_z));
				fputs(file, " ");
				fputs(file, ftos(part.relative_up_x));
				fputs(file, " ");
				fputs(file, ftos(part.relative_up_y));
				fputs(file, " ");
				fputs(file, ftos(part.relative_up_z));
				fputs(file, "\n");
				if (part.mdl != "")
				{
					fputs(file, "model ");
					fputs(file, part.mdl);
					fputs(file, "\n");
				}
				if (part.relative_size)
				{
					fputs(file, "size ");
					fputs(file, ftos(part.relative_size));
					fputs(file, "\n");
				}
				if (part.part_mass)
				{
					fputs(file, "mass ");
					fputs(file, ftos(part.part_mass));
					fputs(file, "\n");
				}
				if (part.physobj_stiction)
				{
					fputs(file, "stiction ");
					fputs(file, ftos(part.physobj_stiction));
					fputs(file, "\n");
				}
				if (vlen(part.physobj_spring))
				{
					fputs(file, "spring ");
					fputs(file, ftos(part.physobj_spring_x));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_spring_y));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_spring_z));
					fputs(file, "\n");
				}
				if (vlen(part.physobj_friction_ground))
				{
					fputs(file, "friction_ground ");
					fputs(file, ftos(part.physobj_friction_ground_x));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_friction_ground_y));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_friction_ground_z));
					fputs(file, "\n");
				}
				if (vlen(part.physobj_friction_water))
				{
					fputs(file, "friction_water ");
					fputs(file, ftos(part.physobj_friction_water_x));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_friction_water_y));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_friction_water_z));
					fputs(file, "\n");
				}
				if (vlen(part.physobj_friction_air))
				{
					fputs(file, "friction_air ");
					fputs(file, ftos(part.physobj_friction_air_x));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_friction_air_y));
					fputs(file, " ");
					fputs(file, ftos(part.physobj_friction_air_z));
					fputs(file, "\n");
				}
				if (part.physobj_bounce)
				{
					fputs(file, "bounce ");
					fputs(file, ftos(part.physobj_bounce));
					fputs(file, "\n");
				}
				if (part.physobj_stepup)
				{
					fputs(file, "stepup ");
					fputs(file, ftos(part.physobj_stepup));
					fputs(file, "\n");
				}
				if (part.physobj_buoyancy)
				{
					fputs(file, "buoyancy ");
					fputs(file, ftos(part.physobj_buoyancy));
					fputs(file, "\n");
				}
				if (part.gravity)
				{
					fputs(file, "gravity ");
					fputs(file, ftos(part.gravity));
					fputs(file, "\n");
				}
				part = part.physobj_next;
			}
		}
		else
		{
			fclose(file);
			print("ERROR: No parts to save\n");
			return;
		}
		part = obj.physobj_hitmodel;
		if (part)
		{
			fputs(file, "hitmodel ");
			fputs(file, part.netname);
			fputs(file, " 0\n");
			if (vlen(part.relative_org))
			{
				fputs(file, "origin ");
				fputs(file, ftos(part.relative_org_x));
				fputs(file, " ");
				fputs(file, ftos(part.relative_org_y));
				fputs(file, " ");
				fputs(file, ftos(part.relative_org_z));
				fputs(file, "\n");
			}
			if (!part.mdl)
			{
				fclose(file);
				print("ERROR: hitmodel without a model\n");
				return;
			}
			fputs(file, "model ");
			fputs(file, part.mdl);
			fputs(file, "\n");
			fputs(file, "matrix ");
			fputs(file, ftos(part.relative_forward_x));
			fputs(file, " ");
			fputs(file, ftos(part.relative_forward_y));
			fputs(file, " ");
			fputs(file, ftos(part.relative_forward_z));
			fputs(file, " ");
			fputs(file, ftos(part.relative_left_x));
			fputs(file, " ");
			fputs(file, ftos(part.relative_left_y));
			fputs(file, " ");
			fputs(file, ftos(part.relative_left_z));
			fputs(file, " ");
			fputs(file, ftos(part.relative_up_x));
			fputs(file, " ");
			fputs(file, ftos(part.relative_up_y));
			fputs(file, " ");
			fputs(file, ftos(part.relative_up_z));
			fputs(file, "\n");
		}
		part = obj.physobj_staticlist;
		while (part)
		{
			fputs(file, "static ");
			fputs(file, part.netname);
			fputs(file, " 0\n");
			if (vlen(part.relative_org))
			{
				fputs(file, "origin ");
				fputs(file, ftos(part.relative_org_x));
				fputs(file, " ");
				fputs(file, ftos(part.relative_org_y));
				fputs(file, " ");
				fputs(file, ftos(part.relative_org_z));
				fputs(file, "\n");
			}
			if (part.mdl)
			{
				fputs(file, "model ");
				fputs(file, part.mdl);
				fputs(file, "\n");
			}
			fputs(file, "matrix ");
			fputs(file, ftos(part.relative_forward_x));
			fputs(file, " ");
			fputs(file, ftos(part.relative_forward_y));
			fputs(file, " ");
			fputs(file, ftos(part.relative_forward_z));
			fputs(file, " ");
			fputs(file, ftos(part.relative_left_x));
			fputs(file, " ");
			fputs(file, ftos(part.relative_left_y));
			fputs(file, " ");
			fputs(file, ftos(part.relative_left_z));
			fputs(file, " ");
			fputs(file, ftos(part.relative_up_x));
			fputs(file, " ");
			fputs(file, ftos(part.relative_up_y));
			fputs(file, " ");
			fputs(file, ftos(part.relative_up_z));
			fputs(file, "\n");
			part = part.physobj_next;
		}
		fputs(file, "makerigid\n"); // spawns sticks
		fputs(file, "EOF\n");
		fclose(file);
		print("Saved successfully to ", sfilename, "\n");
		obj.filename = strzone(sfilename);
	}
	else
		print("There was an error when attempting to save\n");
};

void(string sfilename) Object_Load =
{
	local float file;
	local float args;
	local float makerigid, unknown;
	local float f;
	local float ver;
	local string s, c;
	local entity obj, part;

	file = fopen(sfilename, FILE_READ);

	if (file >= 0)
	{
		s = fgets(file);
		args = tokenize(s);
		while (s != "EOF")
		{
			c = argv(0); // need to fix stupid backwards compatibility, guess I didn't think this through entirely
			if (c == "objectv1")
				c = "object";
			else if (c == "particlev1")
				c = "particle";
			else if (c == "staticv1")
				c = "static";
			else if (c == "hitmodelv1")
				c = "hitmodel";
			if (c == "object")
			{
				obj = spawn();
				obj.think = SUB_Remove;
				obj.nextthink = time;
				f = strlen(sfilename);
				f = f - 5;
				s = substring(sfilename, 5, f);
				obj.filename = strzone(s);
				obj.netname = strzone(argv(1));
				ver = stof(argv(2));
				while (1)
				{
					s = fgets(file);
					args = tokenize(s);
					if (argv(0) == "mass")
						obj.physobj_mass = stof(argv(1));
					else
						break;
				}
			}
			else if (c == "particle")
			{
				part = spawn();
				part.think = SUB_Remove;
				part.nextthink = time;

				part.physobj_next = obj.physobj_particlelist;
				obj.physobj_particlelist = part;

				part.netname = strzone(argv(1));
				ver = stof(argv(2));
				while (1)
				{
					s = fgets(file);
					args = tokenize(s);
					if (!ver) // v1 files
					{
						part.gravity = 1;
						ver = 1;
					}
					if (argv(0) == "origin")
					{
						part.relative_org_x = stof(argv(1));
						part.relative_org_y = stof(argv(2));
						part.relative_org_z = stof(argv(3));
					}
					else if (argv(0) == "model")
						part.mdl = strzone(argv(1));
					else if (argv(0) == "size")
						part.relative_size = stof(argv(1));
					else if (argv(0) == "matrix")
					{
						part.relative_forward_x = stof(argv(1));
						part.relative_forward_y = stof(argv(2));
						part.relative_forward_z = stof(argv(3));
						part.relative_left_x = stof(argv(4));
						part.relative_left_y = stof(argv(5));
						part.relative_left_z = stof(argv(6));
						part.relative_up_x = stof(argv(7));
						part.relative_up_y = stof(argv(8));
						part.relative_up_z = stof(argv(9));
					}
					else if (argv(0) == "mass")
						part.part_mass = stof(argv(1));
					else if (argv(0) == "stiction")
						part.physobj_stiction = stof(argv(1));
					else if (argv(0) == "bounce")
						part.physobj_bounce = stof(argv(1));
					else if (argv(0) == "stepup")
						part.physobj_stepup = stof(argv(1));
					else if (argv(0) == "buoyancy")
						part.physobj_buoyancy = stof(argv(1));
					else if (argv(0) == "gravity")
						part.gravity = stof(argv(1));
					else if (argv(0) == "spring")
					{
						part.physobj_spring_x = stof(argv(1));
						part.physobj_spring_y = stof(argv(2));
						part.physobj_spring_z = stof(argv(3));
					}
					else if (argv(0) == "friction_ground")
					{
						part.physobj_friction_ground_x = stof(argv(1));
						part.physobj_friction_ground_y = stof(argv(2));
						part.physobj_friction_ground_z = stof(argv(3));
					}
					else if (argv(0) == "friction_water")
					{
						part.physobj_friction_water_x = stof(argv(1));
						part.physobj_friction_water_y = stof(argv(2));
						part.physobj_friction_water_z = stof(argv(3));
					}
					else if (argv(0) == "friction_air")
					{
						part.physobj_friction_air_x = stof(argv(1));
						part.physobj_friction_air_y = stof(argv(2));
						part.physobj_friction_air_z = stof(argv(3));
					}
					else if (argv(0) == "friction") // v1 files
					{
						part.physobj_friction_ground_x = stof(argv(1))*100;
						part.physobj_friction_ground_y = stof(argv(1))*100;
						part.physobj_friction_ground_z = stof(argv(1))*100;
					}
					else if (argv(0) == "waterfriction") // v1 files
					{
						part.physobj_friction_water_x = stof(argv(1))*100;
						part.physobj_friction_water_y = stof(argv(1))*100;
						part.physobj_friction_water_z = stof(argv(1))*100;
					}
					else
						break;
				}
			}
			else if (c == "static")
			{
				part = spawn();
				part.think = SUB_Remove;
				part.nextthink = time;

				part.physobj_next = obj.physobj_staticlist;
				obj.physobj_staticlist = part;

				part.netname = strzone(argv(1));
				ver = stof(argv(2));
				while (1)
				{
					s = fgets(file);
					args = tokenize(s);
					if (argv(0) == "origin")
					{
						part.relative_org_x = stof(argv(1));
						part.relative_org_y = stof(argv(2));
						part.relative_org_z = stof(argv(3));
					}
					else if (argv(0) == "model")
						part.mdl = strzone(argv(1));
					else if (argv(0) == "matrix")
					{
						part.relative_forward_x = stof(argv(1));
						part.relative_forward_y = stof(argv(2));
						part.relative_forward_z = stof(argv(3));
						part.relative_left_x = stof(argv(4));
						part.relative_left_y = stof(argv(5));
						part.relative_left_z = stof(argv(6));
						part.relative_up_x = stof(argv(7));
						part.relative_up_y = stof(argv(8));
						part.relative_up_z = stof(argv(9));
					}
					else
						break;
				}
			}
			else if (c == "hitmodel")
			{
				part = spawn();
				part.think = SUB_Remove;
				part.nextthink = time;

				obj.physobj_hitmodel = part;

				part.netname = strzone(argv(1));
				ver = stof(argv(2));
				while (1)
				{
					s = fgets(file);
					args = tokenize(s);
					if (argv(0) == "origin")
					{
						part.relative_org_x = stof(argv(1));
						part.relative_org_y = stof(argv(2));
						part.relative_org_z = stof(argv(3));
					}
					else if (argv(0) == "model")
						part.mdl = strzone(argv(1));
					else if (argv(0) == "matrix")
					{
						part.relative_forward_x = stof(argv(1));
						part.relative_forward_y = stof(argv(2));
						part.relative_forward_z = stof(argv(3));
						part.relative_left_x = stof(argv(4));
						part.relative_left_y = stof(argv(5));
						part.relative_left_z = stof(argv(6));
						part.relative_up_x = stof(argv(7));
						part.relative_up_y = stof(argv(8));
						part.relative_up_z = stof(argv(9));
					}
					else
						break;
				}
			}
			else if (c == "makerigid")
			{
				makerigid = TRUE;
				s = fgets(file);
				args = tokenize(s);
			}
			else
			{
				unknown = TRUE;
				s = fgets(file);
				args = tokenize(s);
			}
		}

		if (!unknown) // loading was fine, lets keep the object
		{
			obj.object_next = object_list;
			object_list = obj;
			obj.think = SUB_Null;
			obj.physobj_flags = obj.physobj_flags | PHFLAGS_FILEBASED;
			part = obj.physobj_particlelist;
			while (part)
			{
				part.owner = obj;
				part.classname = "particle";
				part.think = SUB_Null;
				if (part.mdl != "")
					precache_model(part.mdl);
				part = part.physobj_next;
			}
			part = obj.physobj_staticlist;
			while (part)
			{
				part.owner = obj;
				part.classname = "static";
				part.think = SUB_Null;
				if (part.mdl != "")
					precache_model(part.mdl);
				part = part.physobj_next;
			}
			part = obj.physobj_hitmodel;
			if (part)
			{
				part.owner = obj;
				part.classname = "hitmodel";
				part.think = SUB_Null;
				if (part.mdl != "")
					precache_model(part.mdl);
			}
			if (makerigid)
			{
				physobj_spawning = obj;
				Phys_SpawnSticks();
			}
		}
		fclose(file);
	}
};

void() Object_RemoveAllFileObjects =
{
	local float non_file_object;
	local entity obj, temp;

	obj = object_list;
	while (obj)
	{
		temp = obj.object_next;
		if (obj.physobj_flags & PHFLAGS_FILEBASED)
			Phys_ObjectRemove(obj);
		else
			non_file_object = TRUE;
		obj = temp;
	}
	if (!non_file_object)
		object_list = world;
};

void() Object_LoadAllObjects =
{
	local float f, f2, f3;
	f = search_begin("data/*.ubj", TRUE, FALSE);
	if (f != -1)
	{
		f2 = search_getsize(f);
		while (f3 < f2)
		{
			Object_Load(search_getfilename(f, f3));
			f3 = f3+1;
		}
		search_end(f);
	}
};