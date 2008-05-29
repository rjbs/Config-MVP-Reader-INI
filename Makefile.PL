use inc::Module::Install;
all_from 'lib/Config/INI/MVP/Reader.pm';
requires 'Config::INI::Reader';
extra_tests;
WriteAll;
