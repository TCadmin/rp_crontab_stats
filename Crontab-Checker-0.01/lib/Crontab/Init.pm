package Crontab::Init;

sub new {
    my ($class_name) = @_;

    my $self = {
            _blank => 0,
            _inactiveCron=> 0,
            _activeCron => 0,
            _comment => 0,
            _numberCrons =>0,
            _valid => 0,
            _warning => 0,
            _error => 0,
            _undefined => 0,
            _dir => undef,
            _fileList => [], 
            _messages => []
        };

    bless ($self, $class_name);

    $self->{created} = 1;
    return $self;
}

1;
