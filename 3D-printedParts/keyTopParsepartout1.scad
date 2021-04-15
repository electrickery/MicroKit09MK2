// keyTopParsepartou1

keyTopWidth = 8.0;
keyTopHeight = 5.0;
margin = 0.5;

brim = 3.5;
depth = 0.3;

difference() {
    translate([-brim, -brim, 0])
        cube([keyTopWidth + brim * 2, keyTopHeight + brim * 2, depth]);
    translate([margin, margin, -0.01])
        cube([keyTopWidth - margin * 2, keyTopHeight - margin * 2, depth+ 0.02]);
}