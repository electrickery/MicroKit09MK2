// keyTopLowProfile4

keyTopWidth = 8.0;
keyTopDepth = 5.0;
keyTopThickness = 2.5;

keyTopHole1 = 3.7;
keyTopHole2 = 3.8;
keyTopHoleHeight = 1.0;
keyTopRimZOffset = 3.5;
rimSize = 0.5;
taperSize = 0.3;

module keyTop() {
    rimWidth = keyTopWidth + 2 * rimSize;
    rimDepth = keyTopDepth + 2 * rimSize;
    difference() {
        union() {
            // rim
            cube([rimWidth, rimDepth, rimSize]);
            // top
            translate([rimSize, rimSize, 0]) 
                cube([keyTopWidth, keyTopDepth, keyTopThickness]);
            translate([rimSize, rimSize, keyTopThickness]) 
                trapezoid(keyTopWidth, keyTopDepth, keyTopThickness, taperSize);
        }
        translate([rimWidth / 2, rimDepth / 2, -0.01])
            cylinder(d1 = keyTopHole2, d2 = keyTopHole1, h = keyTopHoleHeight, $fn = 32);
    }
    
}

module trapezoid(width, depth, height, taper) {
    cornerRadius = 0.01;
    $fn = 16;
    hull() {
        // lower plane
        translate([0, 0, cornerRadius]) {
            translate([cornerRadius, cornerRadius, 0]) sphere(r = cornerRadius);
            translate([width - cornerRadius, cornerRadius, 0]) sphere(r = cornerRadius);
            translate([cornerRadius, depth - cornerRadius, 0]) sphere(r = cornerRadius);
            translate([width - cornerRadius, depth - cornerRadius, 0]) sphere(r = cornerRadius);
        }
        // upper plane
        translate([0, 0, taper - cornerRadius]) {
            translate([taper, taper, 0]) sphere(r = cornerRadius);
            translate([width - taper, taper, 0]) sphere(r = cornerRadius);
            translate([taper, depth - taper, 0]) sphere(r = cornerRadius);
            translate([width - taper, depth - taper, 0]) sphere(r = cornerRadius);            
        }
    }
}

keyTop();