use inc::Module::Install;

name 'Geo-Hex3';
all_from 'lib/Geo/Hex3.pm';

requires 'Math::BaseCalc';
requires 'Math::Round';
requires 'Math::Trig';
license 'perl';

WriteAll;
