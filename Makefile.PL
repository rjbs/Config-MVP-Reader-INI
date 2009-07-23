use inc::Module::Install;
all_from 'lib/Config/INI/MVP/Reader.pm';
name 'Config-INI-MVP';
requires 'Config::INI::Reader';
requires 'Config::MVP';
extra_tests;
repository('http://github.com/rjbs/config-ini-mvp');
auto_manifest;
WriteAll;
