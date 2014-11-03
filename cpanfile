requires "Carp" => "0";
requires "Dancer2::Plugin" => "0.153000";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer2" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0.19";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "LWP::UserAgent" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::TCP" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
