float THROWOBJECT = 20;
float PHYSOBJEDITOR = 30;	// Physics Object Editor check value
float WHEELUP = 31;
float WHEELDOWN = 32;
float DRIVINGVEHICLE = 40;

.float clientstate;	// Used to determine wether the client is in the editor or not
.float menu_time, inmenu;	// Menu timing and submenu in editor

.float pe_grid;             // =========
.float pe_zoom;             //
.vector pe_axis;            // Editing values
.float pe_size;             //
.vector pe_move, pe_rot;    // =========

.entity pe_object;		// The current physics object a client is working on
.entity pe_part;			// The selected part of the physics object

.entity pe_org1, pe_org2;	// Axis display

.float mousebuttondown;

float modelindex_box, modelindex_point;