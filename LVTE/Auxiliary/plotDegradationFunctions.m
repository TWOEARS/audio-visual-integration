

figure('name','Visual Degradation Function: Distance');
d=linspace(0,100,180);
ds=visualDegradation_Distance(d);
plot(d,ds);


figure('name','Visual Degradation Function: Azimuth');
a=linspace(-90,90,180);
as=visualDegradation_Azimuth(a);
plot(a,as);

