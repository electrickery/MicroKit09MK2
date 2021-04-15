// keyTop3

keyTopWidth = 8.0;
keyTopHeight = 5.0;
keyTopThickness = 5.0;

keyTopHole1 = 3.2;
keyTopHole2 = 3.7;
keyTopHoleDepth = 4.0;
keyTopRimZOffset = 3.5;
rimSize = 0.5;

module keyTop() {
    keyTopZoffset = keyTopThickness - keyTopHoleDepth;
    difference() {
        union() {
            cube([keyTopWidth, keyTopHeight, keyTopThickness]);
            translate([-rimSize, -rimSize, keyTopRimZOffset])
                cube([keyTopWidth + rimSize * 2, 
                    keyTopHeight + rimSize * 2, keyTopThickness - keyTopRimZOffset]);
        }
        translate([keyTopWidth / 2, keyTopHeight / 2, keyTopZoffset+ 0.01])
            cylinder(d1 = keyTopHole1, d2 = keyTopHole2, h = keyTopHoleDepth, $fn = 32);
    }
}

keyTop();