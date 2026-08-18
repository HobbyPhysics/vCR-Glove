/*
DAEX_dimensions.scad

Shared dimensional parameters for the DAEX-9-4SM actuator assembly.

Units: millimeters

Coordinate convention used by the housing and lower plate:
X = along finger / actuator length
Y = across finger / actuator width
Z = thickness
Housing origin = center of upper housing
Plate origin   = center of lower plate
Top = +Z
Bottom = -Z

This file contains:
- common direct dimensions
- upper-housing dimensions
- lower-plate dimensions
- screw-adjustable tapper dimensions
- common derived dimensions and feature-center coordinates

It intentionally contains no rendered geometry.
*/

// ============================================================================
// Rendering / Boolean-control values
// ============================================================================

upper_fn = 72;
lower_fn = 72;
tapper_fn = 96;

eps = 0.04;
small_extension = 0.08;


// ============================================================================
// Common assembly envelope
// ============================================================================

housing_x = 36.0;
housing_y = 19.7;
housing_z = 11.25;

plate_x = housing_x;
plate_y = housing_y;
plate_z = 3.5;


// ============================================================================
// DAEX actuator and central cavity
// ============================================================================

DAEX_x = 31.0;

cavity_x = 21.3;
cavity_y = 14.0;

// Upper-housing cavity depth measured upward from the housing bottom
cavity_depth = 6.25;

// Lower-plate top pocket depth measured downward from the plate top
cavity_z = 1.8;


// ============================================================================
// Common exterior end- and side-wall dimensions
// ============================================================================

x_wall_width = (housing_x - DAEX_x)/2;
y_wall_width = (housing_y - cavity_y)/2;


// ============================================================================
// Screw system shared by upper housing and lower plate
// ============================================================================

counterbore_d = 5.2;
counterbore_depth = 2.1;

screw_head_offset = 1.0;
screw_offset = counterbore_d/2 + screw_head_offset;

// Four screw/hole center magnitudes from the assembly origin
screw_center_x = housing_x/2 - screw_offset;
screw_center_y = housing_y/2 - screw_offset;

// Upper housing pilot/tap holes
tap_hole_d = 2.25;
tap_hole_depth = 6.0;

// Lower plate clearance holes
clearance_hole_d = 2.75;


// ============================================================================
// Upper-housing exterior fillets
// ============================================================================

comfort_r = 1.0;
comfort_steps = 12;


// ============================================================================
// Upper-housing DAEX ledges
// ============================================================================

ledge_x = 1.65;
ledge_y = 11.4;
ledge_depth = 2.7;

ledge_center_x = cavity_x/2 + ledge_x/2;


// ============================================================================
// Shared contact-cavity geometry
// ============================================================================

contact_cavity_y = 5.1;

// Upper-housing contact-cavity depth
contact_cavity_depth = 2.7;

// Lower-plate contact-cavity depth
contact_cavity_z = cavity_z;

// Contact-cavity X length is the space from the ledge to the inner face
// of the closed +/-X end wall.
contact_cavity_x =
    housing_x/2 -
    cavity_x/2 -
    ledge_x -
    x_wall_width;

// Upper housing: cavity center lies beyond the ledge
upper_contact_cavity_center_x =
    cavity_x/2 +
    ledge_x +
    contact_cavity_x/2;

// Lower plate: cavity runs directly from the central pocket edge
// to the inner face of the closed +/-X end wall.
lower_contact_cavity_x =
    (plate_x - cavity_x)/2 -
    x_wall_width;

lower_contact_cavity_center_x =
    cavity_x/2 +
    lower_contact_cavity_x/2;

contact_cavity_center_y = 0;



// ============================================================================
// Perimeter wire-routing L steps in upper housing
// ============================================================================

// Wire diameter is also the nominal L-step width and depth.
wire_d = 1.10;
wire_step_depth = 1.3;

// Radius produced by the 3/16-inch end mill used on the machined prototype.
// 3/16 in diameter = 4.7625 mm, therefore radius = 2.38125 mm.
wire_step_corner_r = 2.38125;
wire_step_corner_steps = 16;

// Extend the L-step cutter slightly into the contact cavity at the 3rd/4th
// vertices so coincident faces do not leave a zero-thickness Boolean wall.
wire_step_contact_overlap = small_extension;

// Extend vertices 5 and 6 into the ledge subtraction so the two cuts
// overlap and cannot leave a thin Boolean wall.
wire_step_ledge_overlap = small_extension;

// Base six XY vertices for the -X,-Y L-shaped step.
// The geometry script replaces the outer corner (vertex 1) with a quarter
// circle of wire_step_corner_r.  The +X,-Y step is mirrored about X=0.
wire_step_left_points = [
    [-cavity_x/2,                        -cavity_y/2],
    [-cavity_x/2 - ledge_x - wire_d,    -cavity_y/2],
    [-cavity_x/2 - ledge_x - wire_d,
        -contact_cavity_y/2 + wire_step_contact_overlap],
    [-cavity_x/2 - ledge_x,
        -contact_cavity_y/2 + wire_step_contact_overlap],
    [-cavity_x/2 - ledge_x,
        -ledge_y/2 + wire_step_ledge_overlap],
    [-cavity_x/2,
        -ledge_y/2 + wire_step_ledge_overlap]
];

// Derived center of the rounded outer corner for the -X,-Y step.
// The radius is tangent to the bottom horizontal edge and outer vertical edge.
wire_step_left_corner_center_x =
    wire_step_left_points[1][0] + wire_step_corner_r;

wire_step_left_corner_center_y =
    wire_step_left_points[1][1] + wire_step_corner_r;



// ============================================================================
// Upper-housing rectangular wire exit slots
// ============================================================================

// These replace the former matching semicylindrical clamp grooves.
// Strain relief is provided by the perimeter L steps and DAEX frame; the
// rectangular slots simply capture and guide the wires out through the -Y wall.
wire_groove_width = 1.27;
wire_groove_depth = 1.10;
wire_groove_x = 3.56;

wire_groove_center_y =
    -(cavity_y/2 + y_wall_width/2);

// Slot length traverses the full -Y wall, with a small overcut at both ends
// so no thin Boolean skin remains at the cavity or outside surface.
wire_groove_length = y_wall_width + 2*small_extension;


// ============================================================================
// Upper-housing center hole
// ============================================================================

center_hole_d = 7.1;


// ============================================================================
// Upper-housing finger groove
// ============================================================================

finger_groove_x = 27.6;
finger_groove_y = 15.5;
finger_groove_depth = 2.5;
finger_groove_x_offset = 1.7;

finger_groove_plan_radius = 8.0;
finger_groove_side_radius = 3.0;
finger_groove_fillet_radius = 1.0;
finger_groove_steps = 40;

groove_open_end_beyond_housing = 0.60;
finger_groove_open_x_max =
    housing_x/2 + groove_open_end_beyond_housing;


// ============================================================================
// Lower-plate exterior fillets
// ============================================================================

plate_fillet_radius = 0.5;
plate_fillet_steps = 10;


// ============================================================================
// Lower-plate vent slots
// ============================================================================

vent_x = 1.6;
vent_y = 11.2;
vent_center_x = cavity_x/2 - 3*vent_x/2;


// ============================================================================
// Screw-adjustable tapper
// ============================================================================

// Broad upper cylinder bonded to / carried by the DAEX moving element
tapper_mid_d = 11.7;
tapper_mid_z = 0.8;

// Lower locating cylinder
tapper_bottom_d = 6.8;
tapper_bottom_z = 1.3;

// Center through-hole, subsequently tapped for an M2.5 adjustment screw
tapper_hole_d = 2.15;

tapper_total_z =
    tapper_mid_z +
    tapper_bottom_z;

// Tapper-cylinder center Z coordinates when the tapper origin is at the
// center of the complete two-cylinder stack.
tapper_bottom_center_z =
    -tapper_total_z/2 +
    tapper_bottom_z/2;

tapper_mid_center_z =
    -tapper_total_z/2 +
    tapper_bottom_z +
    tapper_mid_z/2;


// ============================================================================
// Assembly-level derived dimensions
// ============================================================================

assembled_body_z = housing_z + plate_z;

// With the housing and plate centered separately in their own files,
// these translations place their mating faces together in an assembly file.
assembly_upper_translate_z = plate_z/2;
assembly_lower_translate_z = -housing_z/2;

// Mating-plane location if the complete assembled body is centered at Z = 0.
assembly_mating_plane_z =
    (plate_z - housing_z)/2;

// Useful minimum material checks
counterbore_edge_clearance = screw_head_offset;

counterbore_to_outer_x =
    plate_x/2 -
    (screw_center_x + counterbore_d/2);

counterbore_to_outer_y =
    plate_y/2 -
    (screw_center_y + counterbore_d/2);
