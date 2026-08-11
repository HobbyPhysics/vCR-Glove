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
// Wire trenches in upper housing
// ============================================================================

wire_trench_y = 1.6;
wire_trench_depth = cavity_depth;
wire_trench_x = contact_cavity_x + ledge_x;

wire_trench_center_x =
    cavity_x/2 +
    wire_trench_x/2;

wire_trench_center_y =
    -contact_cavity_y/2 +
    wire_trench_y/2;


// ============================================================================
// Matching semicylindrical wire-clamp grooves
// ============================================================================

wire_groove_d = 1.0;
wire_groove_x = 3.56;

wire_groove_center_y =
    -(cavity_y/2 + y_wall_width/2);

// Upper groove centerline lies on the upper-housing bottom mating plane
upper_wire_groove_center_z = -housing_z/2;

// Lower groove centerline lies on the lower-plate top mating plane
lower_wire_groove_center_z = plate_z/2;

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
