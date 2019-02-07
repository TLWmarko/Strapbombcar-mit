void() precaches =
{
	precache_model ("progs/null.spr");
	precache_model ("progs/null.mdl");
	precache_model ("progs/point.spr");
	precache_model ("progs/org.mdl");
	precache_model ("progs/org2.mdl");
	precache_model ("progs/partbox.mdl");

	// For test grenade
	//precache_model ("progs/s_explod.spr");
	
	precache_model ("progs/particle_ball.mdl");
	precache_model ("progs/particle_ballflat.mdl");
	precache_model ("progs/particle_star.mdl");
	precache_model ("progs/particle_starflat.mdl");
	precache_model ("progs/particle_rain.mdl");

	//precache_sound ("misc/talk.wav");
	precache_sound("explosion1.wav");
	precache_sound("explosion2.wav");
	precache_sound("explosion3.wav");
};

void() SetNewParms = {};
void() SetChangeParms = {};

entity player; // ultrahax
float game_rain, game_night, game_clouds;
void() StartFrame =
{
	float f;
	string s;

	if (!player)
		return;
	f = cvar("game_rain");
	if (f != game_rain)
	{
		game_rain = f;
	}
	f = cvar("game_clouds");
	if (f != game_clouds)
	{
		game_clouds = f;
	}
	f = cvar("game_night");
	if (f != game_night)
	{
		game_night = f;
		if (game_night)
			stuffcmd(player, "r_ambient 2");
		else
			stuffcmd(player, "r_ambient 65");
	}
};

void() EndFrame = {};

void() main = {};

entity(float lifespan, float sizestart, float sizeend, vector colorstart, vector colorend, float alphastart, float alphaend, string part3dtype) Make3DParticle;

void() MakeSplash =
{
	local entity e;

	e = Make3DParticle(0.2, 5, 10, '0.5 0.5 0.6', '0.5 0.5 0.6', 0.75, 0.0025, "starflat");
	setorigin(e, self.origin);
	e.velocity = '0 0 20';
	e.movetype = MOVETYPE_NOCLIP;
	remove(self);
};

void() SpawnRain =
{
	local entity e;
	local vector vmin, vmax, v;
	local float f;

	self.nextthink = time+0.05;

	if (game_night)
		self.color = '0.25 0.25 0.25';
	else
		self.color = '1 1 1';
	if (!game_clouds)
		self.pflags = 0;
	else
		self.pflags = PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW;
	if (!game_rain)
		return;
	f = 5;
	while (f)
	{
		vmin_z = world.mins_z;
		vmin_x = player.origin_x - 1000;
		vmin_y = player.origin_y - 1000;
		vmax_z = player.origin_z + 100;
		vmax_x = player.origin_x + 1000;
		vmax_y = player.origin_y + 1000;
		v_x = bound(vmin_x, player.origin_x+crandom()*1000, vmax_x);
		v_y = bound(vmin_y, player.origin_y+crandom()*1000, vmax_y);
		//v_z = bound(vmin_z, player.origin_z+crandom()*1000, vmax_z);
		v_z = vmax_z;
		e = Make3DParticle(0.4, 2, 3, '0.5 0.5 0.6', '0.5 0.5 0.6', 0.25, 1, "rain");
		setorigin (e, v);
		e.velocity = '0 0 -5500';
		e.movetype = MOVETYPE_FLY;
		e.touch = MakeSplash;
		e.solid = SOLID_TRIGGER;
		e.effects = EF_DOUBLESIDED;
		f -= 1;
	}
};

void() Spawn_CloudLight = // hax!
{
	local entity e;

	e = spawn();
	e.light_lev = 40000;
	//e.pflags = PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW;
	e.color = '1 1 1';
	e.skin = 19;
	e.avelocity = '2 0 0';
	e.movetype = MOVETYPE_NOCLIP;
	e.think = SpawnRain;
	e.nextthink = time;
	setorigin (e, '0 0 4000');
};

void() worldspawn =
{
	precaches();
	Object_RemoveAllFileObjects();
	Object_LoadAllObjects();
	Spawn_CloudLight();
};

entity(string obj_name) PickObject =
{
	local entity e;

	if (!object_list)
	{
		print("No object\n");
		return world;
	}
	if (obj_name != "")
	{
		e = object_list;
		while (e)
		{
			if (e.netname == obj_name)
				break;
			e = e.object_next;
		}
	}
	else
		e = object_current;
	return e;
};

// entities to be able to display some random maps
void() func_wall =
{
	setmodel(self, self.model);
	self.solid = SOLID_BSP;
};
.float modelscale;
void() misc_gamemodel =
{
	precache_model(self.model);
	setmodel(self, self.model);
	setorigin(self, self.origin);
	if (self.modelscale)
		self.scale = self.modelscale;
};
//end random map stuff

// Half-Life pushables made into twig-objects
void () func_pushable =
{
	setmodel (self, self.model);
	setorigin (self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.angles = '0 0 0';

	self.relative_org = (self.maxs + self.mins)*0.5;
	self.relative_forward = '1 0 0';
	self.relative_left = '0 1 0';
	self.relative_up = '0 0 1';

	// the following lines should be defined in the map object, not in qc
	self.netname = "hl-pushable";
	self.physobj_stiction = 50;
	self.physobj_friction_ground = '7.5 7.5 7.5';
	self.physobj_friction_water = '1 1 1';
	self.physobj_friction_air = '0 0 0';
	self.physobj_bounce = 1;
	self.physobj_buoyancy = 0.3;
	self.physobj_mass = 150;
	self.gravity = 1;

	self.physobj_mass = max(1, self.physobj_mass);
	self.mdl = self.model; // used by the spawning code

	self.enemy = Dynamic_BModelObject(self, self, self);
	makevectors(self.angles);
	Phys_ObjectCreate(self.enemy, self.relative_org, v_forward, v_right * -1, v_up, '0 0 0', 0);
	self.model = ""; // invisible, could be removed instead if you like
};
// End Half-Life pushables

// 3D particle system
.float part3dlife, part3dsizestart, part3dsizeend, part3dalphastart, part3dalphaend;
.vector part3dcolorstart, part3dcolorend;
.float part3dflags;
float PART3DFLAGS_FACEME = 1;
void() Particle3DThink =
{
	local float f;

	self.nextthink = time;
	self.health += frametime;
	if (self.health >= self.part3dlife)
	{
		remove(self);
		return;
	}
	f = self.health/self.part3dlife;
	self.scale = self.part3dsizestart + (self.part3dsizeend-self.part3dsizestart)*f;
	self.alpha = self.part3dalphastart + (self.part3dalphaend-self.part3dalphastart)*f;
	self.colormod_x = self.part3dcolorstart_x + (self.part3dcolorend_x-self.part3dcolorstart_x)*f;
	self.colormod_y = self.part3dcolorstart_y + (self.part3dcolorend_y-self.part3dcolorstart_y)*f;
	self.colormod_z = self.part3dcolorstart_z + (self.part3dcolorend_z-self.part3dcolorstart_z)*f;
	if (self.part3dflags & PART3DFLAGS_FACEME)
	{
		self.angles = vectoangles(player.origin - self.origin);
	}
};

entity(float lifespan, float sizestart, float sizeend, vector colorstart, vector colorend, float alphastart, float alphaend, string part3dtype) Make3DParticle =
{
	local entity part;

	part = spawn();
	
	if (part3dtype == "ball")
	{
		precache_model("progs/particle_ball.mdl");
		setmodel(part, "progs/particle_ball.mdl");
	}
	else if (part3dtype == "ballflat")
	{
		precache_model("progs/particle_ballflat.mdl");
		setmodel(part, "progs/particle_ballflat.mdl");
	}
	else if (part3dtype == "star")
	{
		precache_model("progs/particle_star.mdl");
		setmodel(part, "progs/particle_star.mdl");
	}
	else if (part3dtype == "starflat")
	{
		precache_model("progs/particle_starflat.mdl");
		setmodel(part, "progs/particle_starflat.mdl");
	}
	else if (part3dtype == "rain")
	{
		precache_model("progs/particle_rain.mdl");
		setmodel(part, "progs/particle_rain.mdl");
	}
	part.effects = EF_FULLBRIGHT + EF_NOSHADOW;

	part.part3dlife = lifespan;
	part.part3dsizestart = part.scale = sizestart/10;
	part.part3dsizeend = sizeend/10;
	part.part3dcolorstart = part.colormod = colorstart;
	part.part3dcolorend = colorend;
	part.part3dalphastart = part.alpha = alphastart;
	part.part3dalphaend = alphaend;
	part.classname = "particle3d";

	part.think = Particle3DThink;
	part.nextthink = time;
	return part;
};
// End 3D particle system

void() check_restartgame =
{
	stuffcmd(player, "restart\n");
};

// Car
void() TireThink =
{
	local entity smoke;

	self.nextthink = time;
	tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.lmat_up * self.enemy.physobj_spring_z, TRUE, self);
	setorigin(self, trace_endpos);
	if (self.frags <= time && !player.deadflag)
	{
		self.frags = time + 0.01;
		tracebox(self.enemy.oldorigin, self.enemy.mins, self.enemy.maxs, self.enemy.oldorigin + self.enemy.lmat_up * self.enemy.physobj_spring_z, TRUE, self);
		if (trace_fraction < 1)
		{
			if (vlen(self.enemy.velocity)>1000)
			if (random() < 0.25)
			{
				smoke = Make3DParticle(bound(0.2, random(), 0.7), 10, 25, '1 1 1', '1.5 0.5 0.5', 0.0025, 1, "star");
				setorigin(smoke, trace_endpos);
				smoke.velocity_x = crandom()*100;
				smoke.velocity_y = crandom()*100;
				smoke.velocity_z = 15;
				smoke.avelocity_y = crandom()*300;
				smoke.movetype = MOVETYPE_NOCLIP;
			}
		}
	}
	self.angles = self.enemy.angles;
	self.colormod = self.enemy.colormod;
	self.skin = self.enemy.skin;
	self.effects = self.enemy.effects;
	self.scale = self.enemy.scale;
};

void() ChassiThink =
{
	local vector org;
	local entity smoke;

	self.nextthink = time + 0.01;
	org = self.origin + self.lmat_up*-1 + self.lmat_left*-10 + self.lmat_forward*-26.5;
	smoke = Make3DParticle(bound(0.2, random(), 0.6), 4, 8+random()*5, '0.3 0.3 0.3', '0.0025 0.0025 0.0025', 1, 0.0025, "ballflat");
	setorigin(smoke, org);
	smoke.velocity = randomvec()*10;
	smoke.velocity_z = 20+random()*70;
	smoke.movetype = MOVETYPE_NOCLIP;
	smoke.part3dflags = PART3DFLAGS_FACEME;
};

void() SmokerThink =
{
	local vector org;
	local entity smoke;

	self.nextthink = time + 0.01;
	smoke = Make3DParticle(bound(0.2, random(), 0.6), 8, 10+random()*10, '0.0025 0.0025 0.0025', '0.0025 0.0025 0.0025', 1, 0.0025, "ballflat");
	setorigin(smoke, self.origin + self.lmat_forward*18 + randomvec()*5);
	smoke.velocity = crandom()*'10 10 0';
	smoke.velocity_z = random()*80;
	smoke.movetype = MOVETYPE_NOCLIP;
	smoke.part3dflags = PART3DFLAGS_FACEME;
};

void(entity obj, entity part, vector org, float exp_force) LargeExplosion =
{
	local entity e, head;
	local float stars, whites, fires, smokes;
	local float dist, f;

	stars = 3;
	whites = 20;
	fires = 75;
	smokes = 100;

	head = findradius(org, 300);
	while (head)
	{
		if (head != part)
		if (head.physobj_mass)
		{
			dist = min(300, vlen(head.origin-org));
			dist = 1-(dist/300);
			setvelocity(head, head.velocity + normalize(head.origin - org)*dist*exp_force + '0 0 1'*exp_force*0.75*dist);
			head.flags = head.flags - (head.flags & FL_ONGROUND);
			head.physobj_flags = head.physobj_flags - (head.physobj_flags & PHFLAGS_RESTING);
		}
		head = head.chain;
	}
	f = random();
	if (f < 0.3)
		sound(player, CHAN_BODY, "explosion1.wav", 1, ATTN_NONE);
	else if (f < 0.6)
		sound(player, CHAN_BODY, "explosion2.wav", 1, ATTN_NONE);
	else
		sound(player, CHAN_BODY, "explosion3.wav", 1, ATTN_NONE);

	while (stars)
	{
		e = Make3DParticle(0.15, 45, 20, '1 1 1', '1 1 1', 1, 1, "star");
		setorigin(e, org+randomvec()*25);
		e.angles = randomvec()*360;
		stars -= 1;
	}
	while (whites)
	{
		e = Make3DParticle(0.1, 30, 1, '1 1 1', '1 1 1', 1, 1, "ball");
		setorigin(e, org+randomvec()*25);
		whites -= 1;
	}
	while (fires)
	{
		e = Make3DParticle(0.5, 20, 2, '1.5 1 0.5', '0.0025 0.0025 0.0025', 1, 00.0025, "ballflat");
		setorigin(e, org+randomvec()*10);
		e.velocity = randomvec()*40;
		e.velocity_z = random()*20;
		e.movetype = MOVETYPE_NOCLIP;
		fires -= 1;
	}
	while (smokes)
	{
		e = Make3DParticle(1.8, 3, 20, '0.2 0.2 0.2', '0.0025 0.0025 0.0025', 1, 00.0025, "ballflat");
		setorigin(e, org+randomvec()*8);
		do
		{
			e.velocity = randomvec()*40;
			e.velocity_z = 0;
		}
		while (vlen(e.velocity) < 30);
		e.velocity_z = random()*20;
		e.movetype = MOVETYPE_NOCLIP;
		e.part3dflags = PART3DFLAGS_FACEME;
		smokes -= 1;
	}
	te_customflash(org, 350, 0.2, '1.25 1.25 1');

	e = obj.physobj_particlelist;
	while (e)
	{
		if (e.netname == "chassipart")
		{
			e.part_mass = 1;
			e.think = SUB_Null;
		}
		e.colormod = '0.1 0.1 0.1';
		e = e.physobj_next;
	}
	e = obj.physobj_staticlist;
	while (e)
	{
		if (e.netname == "chassis")
		{
			e.think = SmokerThink;
			e.nextthink = time;
			e.frame = 1;
			e.skin = 1;
		}
		else if (e.netname == "lightleft" || e.netname == "lightright")
		{
			e.pflags = 0;
			e.light_lev = 0;
			e.skin = 0;
		}
		e.colormod = '0.1 0.1 0.1';
		e = e.physobj_next;
	}
	obj.deadflag = player.deadflag = DEAD_DEAD;
	player.think = check_restartgame;
	player.nextthink = time + 3;
};

void(entity part, entity targ) CheckCarBomb =
{
	if (part.netname == "frontbomb")
	{
		LargeExplosion(self, part, part.origin, 1500);
		part.physobj_flags = part.physobj_flags | PHFLAGS_KILLME;
	}
};

void() ChassipartThink =
{
	local entity e;

	if (self.flags & FL_ONGROUND)
		self.health += frametime;
	else
		self.health = 0;
	if (self.health >= 1)
	{
		e = self.realowner.physobj_particlelist;
		while (e)
		{
			if (e.netname == "frontbomb")
			{
				LargeExplosion(self.realowner, e, e.origin, 1000);
				e.physobj_flags = e.physobj_flags | PHFLAGS_KILLME;
			}
			e = e.physobj_next;
		}
	}
	self.nextthink = time;
};

void() LightThink =
{
	self.nextthink = time + 0.05;
	if (game_night)
		self.pflags = PFLAGS_FULLDYNAMIC;
	else
		self.pflags = 0;
};

.entity frontright, frontleft, backright, backleft;
void(entity car) TestCar_InitVehicle =
{
	local entity e;

	car.netname = "testvehicle";
	car.physobj_impactevent = CheckCarBomb;
	e = car.physobj_particlelist;
	while (e)
	{
		if (e.netname == "frontright")
			car.frontright = e;
		else if (e.netname == "frontleft")
			car.frontleft = e;
		else if (e.netname == "backright")
			car.backright = e;
		else if (e.netname == "backleft")
			car.backleft = e;
		else if (e.netname == "chassipart")
		{
			e.think = ChassipartThink;
			e.nextthink = time;
		}
		e = e.physobj_next;
	}
	e = car.physobj_staticlist;
	while (e)
	{
		if (e.netname == "frontright")
		{
			car.frontright.enemy = e;
			e.enemy = car.frontright;
			e.think = TireThink;
			e.nextthink = time;
		}
		else if (e.netname == "frontleft")
		{
			car.frontleft.enemy = e;
			e.enemy = car.frontleft;
			e.think = TireThink;
			e.nextthink = time;
		}
		else if (e.netname == "backright")
		{
			car.backright.enemy = e;
			e.enemy = car.backright;
			e.think = TireThink;
			e.nextthink = time;
		}
		else if (e.netname == "backleft")
		{
			car.backleft.enemy = e;
			e.enemy = car.backleft;
			e.think = TireThink;
			e.nextthink = time;
		}
		else if (e.netname == "chassis")
		{
			e.think = ChassiThink;
			e.nextthink = time;
		}
		else if (e.netname == "lightleft" || e.netname == "lightright")
		{
			e.light_lev = 550;
			e.color = '1 1 1.05';
			//e.pflags = PFLAGS_FULLDYNAMIC;
			e.skin = 16;
			e.think = LightThink;
			e.nextthink = time;
		}
		e = e.physobj_next;
	}
};

void () info_car =
{
	local entity car;

	car = PickObject("car");
	makevectors(self.angles);
	car = Phys_ObjectCreate(car, self.origin, v_forward, v_right * -1, v_up, '0 0 1', 0);
	TestCar_InitVehicle(car);
	remove(self);
};

void(entity veh) TestCar_AttachToVehicle =
{
	self.enemy = veh;
	veh.frontleft.colormod = '0.5 0.5 0.5';
	veh.backleft.colormod = '0.5 0.5 0.5';
	veh.frontright.colormod = '0.5 0.5 0.5';
	veh.backright.colormod = '0.5 0.5 0.5';

	self.movetype = MOVETYPE_NOCLIP;
	self.solid = SOLID_NOT;
	self.velocity = '0 0 0';
	self.clientstate = DRIVINGVEHICLE;
};

void(float booldir, float speed) TestCar_Accelerate =
{
	local entity tright, tleft;

	if (!self.enemy)
		return;
	tleft = self.enemy.backleft;
	tright = self.enemy.backright;
	tright.physobj_flags = tright.physobj_flags - (tright.physobj_flags & PHFLAGS_RESTING);
	tleft.physobj_flags = tleft.physobj_flags - (tleft.physobj_flags & PHFLAGS_RESTING);
	if (tright.flags & FL_ONGROUND)
		tright.velocity = tright.velocity + normalize(tright.lmat_forward) *speed*booldir*frametime;
	if (tleft.flags & FL_ONGROUND)
		tleft.velocity = tleft.velocity + normalize(tleft.lmat_forward) *speed*booldir*frametime;
};

void(float booldir) TestCar_Turn =
{
	local float f;
	local entity tright, tleft;

	if (!self.enemy)
		return;
	tleft = self.enemy.frontleft;
	tright = self.enemy.frontright;
	tright.physobj_flags = tright.physobj_flags - (tright.physobj_flags & PHFLAGS_RESTING);
	tleft.physobj_flags = tleft.physobj_flags - (tleft.physobj_flags & PHFLAGS_RESTING);
	f = 12;
	if (booldir < 0)
		self.enemy.ideal_yaw = max(-32, self.enemy.ideal_yaw - f*frametime);
	else if (booldir > 0)
		self.enemy.ideal_yaw = min(32, self.enemy.ideal_yaw + f*frametime);
	else if (!booldir)
	{
	/*	if (self.enemy.ideal_yaw < 0)
			self.enemy.ideal_yaw = min(0, self.enemy.ideal_yaw + 200*frametime);
		else if (self.enemy.ideal_yaw > 0)
			self.enemy.ideal_yaw = max(0, self.enemy.ideal_yaw - 200*frametime);
		else*/
			self.enemy.ideal_yaw = 0;
	}
	// left tire
	matrix_forward = tleft.save_forward;
	matrix_left = tleft.save_left;
	matrix_up = tleft.save_up;
	Matrix_RotateByAxisAngle('0 0 1', self.enemy.ideal_yaw);
	tleft.relative_forward = matrix_forward;
	tleft.relative_left = matrix_left;
	tleft.relative_up = matrix_up;
	// right tire
	matrix_forward = tright.save_forward;
	matrix_left = tright.save_left;
	matrix_up = tright.save_up;
	Matrix_RotateByAxisAngle('0 0 1', self.enemy.ideal_yaw);
	tright.relative_forward = matrix_forward;
	tright.relative_left = matrix_left;
	tright.relative_up = matrix_up;
};

void(entity car) TestCar_Flip =
{
	local entity e;

	e = car.physobj_particlelist;
	while(e)
	{
		if (e.netname == "chassipart")
		if (e.flags & FL_ONGROUND)
		{
			e.physobj_flags = e.physobj_flags - (e.physobj_flags & PHFLAGS_RESTING);
			setvelocity(e, e.velocity + e.physobj_floor_plane_normal*30000*(1/e.part_mass)*frametime);
			//e.velocity = e.velocity + e.physobj_floor_plane_normal*30000*(1/e.part_mass)*frametime;
		}
		e = e.physobj_next;
	}
};
// End car

// Trees and grass
void() info_tree =
{
	local vector v;
	local vector siz_min, siz_max;

	self.mdl = "progs/tree/tree3.mdl";
	precache_model(self.mdl);
	setmodel(self, self.mdl);
	self.scale = 1+random();
	siz_min = '-6 -6 -16'*self.scale;
	siz_max = '6 6 124'*self.scale;
	setsize(self, siz_min, siz_max);
	self.solid = SOLID_BBOX;
	self.angles_y = random()*360;
	v = self.origin + '0 0 -16';
	setorigin(self, v + '0 0 1'*(2-self.scale)*16);
};

void() info_grass =
{
	self.mdl = "progs/grass/grass1.mdl";
	precache_model(self.mdl);
	setmodel(self, self.mdl);
	self.angles_y = random()*360;
	self.scale = max(0.3, random());
	setorigin(self, self.origin + '0 0 1'*(1-self.scale)*-16);
	self.effects = EF_NOSHADOW;
};
// End trees and grass

// Goal and checkpoints

float timer;
.float checkstate;
float CHECK_INACTIVE = 1;
float CHECK_ACTIVE = 2;

entity hiscore_list, hiscore_end;
.entity hiscore_next, hiscore_prev;

void() ClearHiscores =
{
	local entity e;

	e = hiscore_list;
	while (e)
	{
		e.think = SUB_Remove;
		e.nextthink = time;
		e = e.hiscore_next;
	}
	hiscore_list = world;
};

float SORT_INCREASING = 1;
float SORT_DECREASING = 2;
entity sortlist_start;
entity sortlist_end;
void(.entity list_next, .entity list_prev, .float val, float sort) SortList =
{
	local entity e, e2;

	e = sortlist_start;
	while (e)
	{
		e2 = e.list_next;
		if (e2 && ((sort == SORT_INCREASING && e.val > e2.val) || (sort == SORT_DECREASING && e.val < e2.val)))
		{
			if (e.list_prev)
				e.list_prev.list_next = e2;
			if (e2.list_next)
				e2.list_next.list_prev = e;
			e.list_next = e2.list_next;
			e2.list_next = e;
			e2.list_prev = e.list_prev;
			e.list_prev = e2;
			if (e == sortlist_start)
				sortlist_start = e2;
			if (e2 == sortlist_end)
				sortlist_end = e;
			e = sortlist_start;
		}
		else
			e = e.list_next;
	}
};

void() OpenHiscoreList =
{
	local entity e;
	local float file;
	local string s;

	ClearHiscores();
	file = fopen("hiscores.txt", FILE_READ);
	if (file >= 0)
	{
		s = fgets(file);
		while (s != "")
		{
			e = spawn();
			e.health = stof(s);
			if (!hiscore_list)
				hiscore_list = hiscore_end = e;
			else
			{
				hiscore_end.hiscore_next = e;
				e.hiscore_prev = hiscore_end;
				hiscore_end = e;
			}
			s = fgets(file);
		}
		fclose(file);
	}
	sortlist_start = hiscore_list;
	sortlist_end = hiscore_end;
	SortList(hiscore_next, hiscore_prev, health, SORT_INCREASING);
	hiscore_list = sortlist_start;
	hiscore_end = sortlist_end;
};

entity(float score) AddHiscore =
{
	local entity new;

	new = spawn();
	new.health = score;
	if (!hiscore_list)
	{
		hiscore_list = hiscore_end = new;
	}
	else
	{
		hiscore_end.hiscore_next = new;
		new.hiscore_prev = hiscore_end;
		hiscore_end = new;
	}
	sortlist_start = hiscore_list;
	sortlist_end = hiscore_end;
	SortList(hiscore_next, hiscore_prev, health, SORT_INCREASING);
	hiscore_list = sortlist_start;
	hiscore_end = sortlist_end;

	return new;
};

void() SaveScores =
{
	local entity e;
	local float file;

	sortlist_start = hiscore_list;
	sortlist_end = hiscore_end;
	SortList(hiscore_next, hiscore_prev, health, SORT_INCREASING);
	hiscore_list = sortlist_start;
	hiscore_end = sortlist_end;
	file = fopen("hiscores.txt", FILE_WRITE);
	if (file >= 0)
	{
		e = hiscore_list;
		while (e)
		{
			fputs(file, ftos(e.health));
			fputs(file, "\n");
			e = e.hiscore_next;
		}
		fclose(file);
	}
};

void() check_touch =
{
	local float cur, hiscore, f;
	entity e, new;
	local string s, pr;

	if (other.classname == "particle3d")
		return;
	if (self.checkstate == CHECK_ACTIVE)
	{
		self.checkstate = CHECK_INACTIVE;
		if (self.target != "")
		{
			centerprint(player, "Checkpoint:\n", ftos(time-timer), "\n");
			e = find(world, targetname, self.target);
			e.checkstate = CHECK_ACTIVE;
		}
		else
		{
			cur = time-timer;
			OpenHiscoreList();
			hiscore = hiscore_list.health;
			if (hiscore < cur && hiscore_list)
				pr = strcat("Your time was:\n", ftos(cur), "\n", ftos(cur-hiscore), " seconds slower than the hiscore\n\n");
			else
			{
				if (!hiscore_list)
					pr = strcat("Your time was:\n", ftos(cur), "\n", "^1NEW RECORD!^7\n\n");
				else
					pr = strcat("Your time was:\n", ftos(cur), "\n^4", ftos(hiscore-cur), "^7 seconds faster than the hiscore!\n", "^1NEW RECORD!^7\n\n");
			}
			new = AddHiscore(cur);
			e = hiscore_list;
			f = 0;
			while (e && f != 5)
			{
				if (e == new)
					s = strcat(s, "^4", ftos(e.health), "^7", "\n");
				else
					s = strcat(s, ftos(e.health), "\n");
				e = e.hiscore_next;
				f += 1;
			}
			SaveScores();
			centerprint(player, pr, "Hiscores:\n", s);
			self.think = check_restartgame;
			self.nextthink = time + 4;
		}
	}
};

void() trigger_once =
{
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);	// set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	if (self.targetname == "")
		self.checkstate = CHECK_ACTIVE;
	else
		self.checkstate = CHECK_INACTIVE;
	self.touch = check_touch;
};

// End goal and checkpoints

void() info_player_start        = {};
void() info_player_start2       = {};
void() info_player_deathmatch   = {};
void() info_player_coop         = {};
void() info_player_team1		= {};
void() info_player_team2		= {};

// Test objects
entity(string obj_name) ThrowObject =
{
	local entity e;

	e = PickObject(obj_name);
	makevectors(self.v_angle);
	e = Phys_ObjectCreate(e, self.origin + v_forward*50, v_forward, v_right * -1, v_up, v_forward*600+v_up*200, 200);
	if (e.netname == "car")
		TestCar_InitVehicle(e);
	else if (e.netname == "carnosusp")
		TestCar_InitVehicle(e);
	else if (e.netname == "audi")
		TestCar_InitVehicle(e);
	return e;
};

// Gravity gun particle
entity(vector org, entity object) GravGunParticle =
{
	local entity e;

	e = Phys_AddParticleToObject(org, object);
    e.part_mass = 1;
    e.physobj_bounce = 1;
    e.physobj_friction_ground = '0 0 0';
    e.physobj_friction_water = '0 0 0';
    e.physobj_friction_air = '0 0 0';
    e.physobj_buoyancy = 0;
	e.physobj_stiction = 0;
   	e.physobj_mass = object.physobj_mass;
   	e.physobj_inversemass = 0;
	e.gravity = 0;
	setmodel(e, "progs/point.spr");
	e.effects = EF_NODEPTHTEST;
	return e;
};

// Hacky test grenade
void() GrenadeExplode =
{
	local float dist, mass_scaler;
	local entity head;

	effect (self.origin, "progs/s_explod.spr", 0, 6, 10);
	te_explosion(self.origin);

	head = findradius(self.origin, 200);
	while (head)
	{
		if (head != self)
		if (head.physobj_mass)
		{
			dist = 200-vlen(head.origin-self.origin);
			dist = dist/200;
			mass_scaler = 100/head.physobj_mass;
			setvelocity(head, head.velocity + normalize(head.origin - self.origin)*dist*1000*mass_scaler + '0 0 300'*dist);
			//head.velocity = head.velocity + normalize(head.origin - self.origin)*dist*1000*mass_scaler + '0 0 300'*dist;
			head.flags = head.flags - (head.flags & FL_ONGROUND);
			head.physobj_flags = head.physobj_flags - (head.physobj_flags & PHFLAGS_RESTING);
		}
		head = head.chain;
	}
	Phys_ObjectRemove(self);
};

// Impulses
void(float i) ImpulseCommands =
{
	local entity e;

	if (self.inmenu && i >= 1 && i <= 9)
		return;
	else if (i == PHYSOBJEDITOR)
	if (self.clientstate != DRIVINGVEHICLE)
		Editor_SetupPhysObjEditor();
	if (self.clientstate == PHYSOBJEDITOR)
		return;
	else if (i == WHEELUP)
	{
		object_current = object_current.object_next;
		if (!object_current)
			object_current = object_list;
		print(object_current.netname, "\n");
	}
	else if (i == WHEELDOWN)
	{
		e = object_list;
		while (e)
		{
			if (e.object_next == object_current)
			{
				object_current = e;
				break;
			}
			else if (!e.object_next)
				object_current = e;
			e = e.object_next;
		}
		print(object_current.netname, "\n");
	}
	else if (i == THROWOBJECT)
	{
		if (self.pe_object)
		{
			Phys_ObjectRemove(self.pe_object);
			self.pe_part = self.pe_object = world;
		}
		else
			ThrowObject("");
	}
	else if (i == DRIVINGVEHICLE)
	{
		if (self.clientstate == DRIVINGVEHICLE)
		{
			PutClientInServer();
			return;
		}
		e = findradius(self.origin, 64);
		while(e)
		{
			if (e.netname == "testvehicle")
			{
				TestCar_AttachToVehicle(e);
				return;
			}
			e = e.chain;
		}
	}
	else if (i == 41)
		TestCar_Flip(self.enemy);
};

void() ClientKill = {};
void() ClientConnect = {};
void() ClientDisconnect = {};

.float lip;
float FL_PRESSED = 8192;
float FL_TURN = 16384;
void() PlayerPreThink =
{
	local float f, zoomlevel;
	local entity e;

	if (self.clientstate == PHYSOBJEDITOR)
	{
		Editor_Refresh();
		return;
	}
	else if (self.clientstate == DRIVINGVEHICLE)
	{
		if (self.enemy.origin_z < 80)
		{
			f = min(2000, vlen(self.enemy.velocity));
			f = f/2000;
			zoomlevel = 0.65+f*0.35;
		}
		else
		{
			f = min(1500, self.enemy.origin_z);
			f = f/1500;
			zoomlevel = max(0.28, 1-f);
		}
		zoomlevel = zoomlevel - self.viewzoom;
		self.viewzoom = self.viewzoom + zoomlevel*frametime*7;
		if (self.deadflag)
			return;
		if (self.button0)
		{
			if (!(self.flags & FL_PRESSED))
			{
				if (!(self.flags & FL_TURN))
				{
					self.flags = self.flags | FL_TURN;
					self.enemy.frontright.colormod = '1 1 1';
					self.enemy.frontright.effects = 0;
					self.enemy.frontright.skin = 0;
					self.enemy.backright.colormod = '1 1 1';
					self.enemy.backright.effects = 0;
					self.enemy.backright.skin = 0;
					self.enemy.frontleft.colormod = '0 2 2';
					self.enemy.frontleft.effects = EF_FULLBRIGHT;
					self.enemy.frontleft.skin = 1;
					self.enemy.backleft.colormod = '0 2 2';
					self.enemy.backleft.effects = EF_FULLBRIGHT;
					self.enemy.backleft.skin = 1;
				}
				else
				{
					self.flags = self.flags - (self.flags & FL_TURN);
					self.enemy.frontright.colormod = '0 2 2';
					self.enemy.frontright.effects = EF_FULLBRIGHT;
					self.enemy.frontright.skin = 1;
					self.enemy.backright.colormod = '0 2 2';
					self.enemy.backright.effects = EF_FULLBRIGHT;
					self.enemy.backright.skin = 1;
					self.enemy.frontleft.colormod = '1 1 1';
					self.enemy.frontleft.effects = 0;
					self.enemy.frontleft.skin = 0;
					self.enemy.backleft.colormod = '1 1 1';
					self.enemy.backleft.effects = 0;
					self.enemy.backleft.skin = 0;
				}
			}
			self.lip = 0;
			self.flags = self.flags | FL_PRESSED;
			TestCar_Accelerate(1, 2500);
			if (timer == 0)
				timer = time;
		}
		else if (!self.button0)
		{
			if (self.flags & FL_PRESSED)
			{
				if (self.flags & FL_TURN)
					self.lip = -1;
				else
					self.lip = 1;
			}
			self.flags = self.flags - (self.flags & FL_PRESSED);
		}
		TestCar_Turn(self.lip);
		if (timer > 0)
			TestCar_Accelerate(1, 750);
		return;
	}
/*
	tracebox(self.cursor_trace_endpos, '-8 -8 -8', '8 8 8', self.cursor_trace_endpos + '-1 1 -1', TRUE, self);
	print(ftos(trace_fraction), "\n");
	print(vtos(trace_plane_normal), "\n");
*/
	tracebox(self.origin, self.mins, self.maxs, self.origin + self.velocity*frametime, FALSE, self);
	Phys_Force(trace_ent, self.physobj_mass, self.velocity, Clamp(self.origin + self.maxs, self.origin + self.mins, trace_ent.owner.origin), trace_plane_normal);

	if (self.pe_part)
	{
		f = 1/frametime;
		makevectors(self.v_angle);
		setvelocity(self.pe_part, ((self.origin+v_forward*self.pe_zoom)-self.pe_part.origin)*f);
	}

	// Gravity gun
	if (self.button0)
	{
		if (self.flags & 16384)
			return;
		if (!(self.flags & 8192))
			self.ltime = time;
		self.flags = self.flags | 8192;
		if (self.pe_part)
		{
			if (time > self.ltime + 1)
			{
				Phys_ObjectRemoveParticle(self.pe_part, self.pe_object);
				self.pe_object.physobj_flags = self.pe_object.physobj_flags - (self.pe_object.physobj_flags & PHFLAGS_ATTACHED);
				self.pe_part = self.pe_object = world;
				self.flags = self.flags - (self.flags & 8192);
				self.flags = self.flags | 16384;
			}
		}
		else if (!(self.flags & 16384))
		{
			self.flags = self.flags | 16384;
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + v_forward*2048, FALSE, self);
			self.pe_zoom = 2048*trace_fraction;
			te_gunshot(trace_endpos);
			if (trace_ent.classname == "hitmodel")
			{
				self.pe_object = trace_ent.owner;
				self.pe_part = GravGunParticle(trace_endpos, self.pe_object);
				self.pe_object.physobj_flags = self.pe_object.physobj_flags - (self.pe_object.physobj_flags & PHFLAGS_RESTING);
				self.pe_object.physobj_flags = self.pe_object.physobj_flags | PHFLAGS_ATTACHED;
			}
		}
	}
	else if (!self.button0)
	{
		if (self.flags & 8192)
		if (!(self.flags & 16384))
		{
			makevectors(self.v_angle);
			Phys_ObjectRemoveParticle(self.pe_part, self.pe_object);
			self.pe_object.physobj_flags = self.pe_object.physobj_flags - (self.pe_object.physobj_flags & PHFLAGS_ATTACHED);
			Phys_Force(self.pe_object, self.pe_object.physobj_mass, v_forward*1800 + v_up*750, self.pe_object.origin, v_forward);
			self.pe_part = self.pe_object = world;
		}
		self.flags = self.flags - (self.flags & 16384);
		self.flags = self.flags - (self.flags & 8192);
	}
	if (self.button2)
	{
		if (self.flags & 32768)
			return;
		self.flags = self.flags | 32768;
		e = ThrowObject("grenade");
		e.physobj_think = GrenadeExplode;
		e.physobj_nextthink = time + 3;
	}
	else if (!self.button2)
		self.flags = self.flags - (self.flags & 32768);
};
void() PlayerPostThink =
{
	if (self.clientstate == PHYSOBJEDITOR)
		Editor_Menu();
	else if (self.clientstate == DRIVINGVEHICLE)
	{
		//v = vectoangles(self.enemy.lmat_forward*-1);
		//v_x = 0;
		//makevectors(v);
		//setorigin(self, self.enemy.origin + '0 0 70' + v_forward*80);
		//self.angles = vectoangles(self.enemy.origin+v_forward*200*-1 - self.origin);
		setorigin(self, self.enemy.origin + '-150 -260 400');
		self.angles = vectoangles(self.enemy.origin - self.origin);
		self.angles_x = self.angles_x*-1;
		self.fixangle = TRUE;
	}

	if (self.impulse)
		ImpulseCommands(self.impulse);
	self.impulse = 0;

	self.button0 = self.button1 = self.button2 = 0;
};

entity() FindSpawnSpot =
{
	local entity spot;

	spot = find(world, classname, "info_player_start");
	if (spot)
		return spot;
	spot = find(world, classname, "info_player_start2");
	if (spot)
		return spot;
	spot = find(world, classname, "info_player_deathmatch");
	if (spot)
		return spot;
	spot = find(world, classname, "info_player_coop");
	if (spot)
		return spot;
	spot = find(world, classname, "info_player_team1");
	if (spot)
		return spot;
	spot = find(world, classname, "info_player_team2");
	if (spot)
		return spot;
	return world;
};

void() PutClientInServer =
{
	local entity spawn_spot, car;

	spawn_spot = FindSpawnSpot();

	self.classname = "player";
	self.health = self.max_health = 100;
	self.takedamage = DAMAGE_NO;
	//self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_NOCLIP;
	self.flags = FL_CLIENT | FL_TURN;

	setorigin (self, spawn_spot.origin + '0 0 1');
	self.angles = spawn_spot.angles;
	self.fixangle = TRUE;

	setmodel (self, "progs/null.mdl");
	setsize (self, '-16 -16 -28', '16 16 28');

	self.view_ofs = '0 0 0';
	self.velocity = '0 0 0';
	//self.clientstate = 0;
	self.pe_grid = 2;
	self.pe_axis = '1 0 0';

	self.physobj_mass = 0;
	car = PickObject("car");
	makevectors(self.angles);
	car = Phys_ObjectCreate(car, self.origin, v_forward, v_right * -1, v_up, '0 0 1', 0);
	TestCar_InitVehicle(car);
	TestCar_AttachToVehicle(car);
	player = self;
};

void(string s) SV_ParseClientCommand =
{
	local float args;
	local string c;

	args = tokenize(s);
	c = argv(0);
	if (c == "say")
		Editor_Commands();
	clientcommand(self, s);
};

float lastclientthink, sv_maxspeed, sv_friction, sv_accelerate, sv_stopspeed;
float sv_edgefriction, cl_rollangle, cl_divspeed;

// LordHavoc:
// Highly optimized port of SV_ClientThink from engine code to QuakeC.
// No behavior changes!  This code is much shorter and probably faster than
// the engine code :)

// note that darkplaces engine will call this function if it finds it,
// so modify for your own mods and enjoy...

// note also, this code uses some builtin functions from dpextensions.qc
// (included with darkplaces engine releases)

void() SV_PlayerPhysics =
{
	local vector wishvel, wishdir, v;
	local float wishspeed, f;

	if (self.movetype == MOVETYPE_NONE)
		return;

	if (self.punchangle != '0 0 0')
	{
		f = vlen(self.punchangle) - 10 * frametime;
		if (f > 0)
			self.punchangle = normalize(self.punchangle) * f;
		else
			self.punchangle = '0 0 0';
	}

	// if dead, behave differently
	if (self.health <= 0)
		return;

	if (time != lastclientthink)
	{
		lastclientthink = time;
		sv_maxspeed = cvar("sv_maxspeed");
		sv_friction = cvar("sv_friction");
		sv_accelerate = cvar("sv_accelerate");
		sv_stopspeed = cvar("sv_stopspeed");
		sv_edgefriction = cvar("edgefriction");
		// LordHavoc: this * 4 is an optimization
		cl_rollangle = cvar("cl_rollangle") * 4;
		// LordHavoc: this 1 / is an optimization
		cl_divspeed = 1 / cvar("cl_rollspeed");
	}

	// show 1/3 the pitch angle and all the roll angle
	// self.angles_z = bound(-1, self.velocity * v_right * cl_divspeed, 1) * cl_rollangle;
	if (!self.fixangle)
	{
		self.angles_x = (self.v_angle_x + self.punchangle_x) * -0.333;
		self.angles_y = self.v_angle_y + self.punchangle_y;
	}

	if (self.clientstate == DRIVINGVEHICLE)
	{
		/*
		self.enemy.physobj_flags = self.enemy.physobj_flags - (self.enemy.physobj_flags & PHFLAGS_RESTING);
		f = 1;
		if (self.movement_x < 0)
			f = -1;
		if (self.movement_x != 0)
			TestCar_Accelerate(f);
		f = 0;
		if (self.movement_y < 0)
			f = -1;
		if (self.movement_y > 0)
			f = 1;
		TestCar_Turn(f);
		*/
		return;
	}

	if (self.flags & FL_WATERJUMP )
	{
		self.velocity_x = self.movedir_x;
		self.velocity_y = self.movedir_y;
		if (time > self.teleport_time || self.waterlevel == 0)
		{
			self.flags = self.flags - (self.flags & FL_WATERJUMP);
			self.teleport_time = 0;
		}
		return;
	}

	makevectors(self.v_angle);

	// swim
	if (self.waterlevel >= 2)
	if (self.movetype != MOVETYPE_NOCLIP && self.movetype != MOVETYPE_FLY)
	{
		self.flags = self.flags - (self.flags & FL_ONGROUND);

		if (self.movement == '0 0 0')
			wishvel = '0 0 -60'; // drift towards bottom
		else
			wishvel = v_forward * self.movement_x + v_right * self.movement_y + '0 0 1' * self.movement_z;

		wishspeed = vlen (wishvel);
		if (wishspeed > sv_maxspeed)
			wishspeed = sv_maxspeed;

		wishspeed = wishspeed * 0.7;

		// water friction
		if (self.velocity != '0 0 0')
		{
			f = vlen(self.velocity) * (1 - frametime * sv_friction);
			if (f > 0)
				self.velocity = normalize(self.velocity) * f;
			else
				self.velocity = '0 0 0';
		}
		else
			f = 0;

		// water acceleration
		if (wishspeed <= f)
			return;

		f = min(wishspeed - f, sv_accelerate * wishspeed * frametime);
		self.velocity = self.velocity + normalize(wishvel) * f;
		return;
	}

	// hack to not let you back into teleporter
	if (time < self.teleport_time && self.movement_x < 0)
		wishvel = v_right * self.movement_y;
	else
	{
		// LordHavoc: this NOCLIP check is a fix for the 'not moving while looking straight up/down when noclipping' bug in Quake
		if ((self.flags & FL_ONGROUND) || (self.movetype == MOVETYPE_NOCLIP))
			makevectors (self.v_angle_y * '0 1 0');

		wishvel = v_forward * self.movement_x + v_right * self.movement_y;
	}

	//if (self.movetype != MOVETYPE_WALK)
	//	wishvel_z = self.movement_z;
	if (self.movetype == MOVETYPE_WALK)
		wishvel_z = 0;

	wishdir = normalize(wishvel);
	wishspeed = vlen(wishvel);
	if (wishspeed > sv_maxspeed)
		wishspeed = sv_maxspeed;

	if (self.movetype == MOVETYPE_NOCLIP || self.movetype == MOVETYPE_FLY) // noclip or fly
	{
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		self.velocity = wishdir * wishspeed;
	}
	else if (self.flags & FL_ONGROUND) // walking
	{
		// friction
		if (self.velocity_x || self.velocity_y)
		{
			v = self.velocity;
			v_z = 0;
			f = vlen(v);

			// if the leading edge is over a dropoff, increase friction
			v = self.origin + normalize(v) * 16 + '0 0 1' * self.mins_z;

			traceline(v, v + '0 0 -34', TRUE, self);

			// apply friction
			if (trace_fraction == 1.0)
			{
				if (f < sv_stopspeed)
					f = 1 - frametime * (sv_stopspeed / f) * sv_friction * sv_edgefriction;
				else
					f = 1 - frametime * sv_friction * sv_edgefriction;
			}
			else
			{
				if (f < sv_stopspeed)
					f = 1 - frametime * (sv_stopspeed / f) * sv_friction;
				else
					f = 1 - frametime * sv_friction;
			}

			if (f < 0)
				self.velocity = '0 0 0';
			else
				self.velocity = self.velocity * f;
		}

		// acceleration
		f = wishspeed - (self.velocity * wishdir);
		if (f > 0)
			self.velocity = self.velocity + wishdir * min(f, sv_accelerate * frametime * wishspeed);
	}
	else // airborn
	{
		if (wishspeed < 30)
			f = wishspeed - (self.velocity * wishdir);
		else
			f = 30 - (self.velocity * wishdir);
		if (f > 0)
			self.velocity = self.velocity + wishdir * (min(f, sv_accelerate) * wishspeed * frametime);
	}
};
