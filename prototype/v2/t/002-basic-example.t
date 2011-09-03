#!perl

use strict;
use warnings;

use Test::More;

use mop;

# FIXME:
# we should be able to import
# these, but exactly how is
# currently escaping me.
# - SL
my ($self, $class);

=pod

Here is how this example might look with the real syntax:

  class BankAccount {
      has $balance;

      method balance { $balance }

      method deposit ($amount) { $balance += $amount }

      method withdraw ($amount) {
          ($balance >= $amount)
              || die "Account overdrawn";
          $balance -= $amount;
      }
  }

  class CheckingAccount extends BankAccount {
      has $overdraft_account;

      method overdraft_account { $overdraft_account }

      method withdraw ($amount) {

          my $overdraft_amount = $amount - $self->balance;

          if ( $overdraft_account && $overdraft_amount > 0 ) {
              $overdraft_account->withdraw( $overdraft_amount );
              $self->deposit( $overdraft_amount );
          }

          $self->next::method( $amount );
      }
  }

=cut

my $BankAccount = class {
    has my $balance;

    method 'balance' => sub { $balance };

    method 'deposit' => sub {
        my $amount = shift;
        $balance += $amount;
    };

    method 'withdraw' => sub {
        my $amount = shift;
        ($balance >= $amount)
            || die "Account overdrawn";
        $balance -= $amount;
    };
};

my $CheckingAccount = class {
    extends $BankAccount;

    has my $overdraft_account;

    method 'overdraft_account' => sub { $overdraft_account };

    method 'withdraw' => sub {
        my $amount = shift;

        my $overdraft_amount = $amount - $self->balance;

        if ( $overdraft_account && $overdraft_amount > 0 ) {
            $overdraft_account->withdraw( $overdraft_amount );
            $self->deposit( $overdraft_amount );
        }

        $self->NEXTMETHOD( 'withdraw', $amount );
    };
};

ok $BankAccount->is_subclass_of( $::Object ), '... BankAccount is a subclass of Object';

ok $CheckingAccount->is_subclass_of( $BankAccount ), '... CheckingAccount is a subclass of BankAccount';
ok $CheckingAccount->is_subclass_of( $::Object ), '... CheckingAccount is a subclass of Object';

my $savings = $BankAccount->new( balance => 250 );
is $savings->class, $BankAccount, '... got the class we expected';
ok $savings->is_a( $BankAccount ), '... savings is an instance of BankAccount';

is $savings->balance, 250, '... got the savings balance we expected';

$savings->withdraw( 50 );
is $savings->balance, 200, '... got the savings balance we expected';

$savings->deposit( 150 );
is $savings->balance, 350, '... got the savings balance we expected';

my $checking = $CheckingAccount->new(
    balance           => 100,
    overdraft_account => $savings,
);
is $checking->class, $CheckingAccount, '... got the class we expected';
ok $checking->is_a( $CheckingAccount ), '... checking is an instance of BankAccount';
ok $checking->is_a( $BankAccount ), '... checking is an instance of BankAccount';

is $checking->balance, 100, '... got the checking balance we expected';
is $checking->overdraft_account, $savings, '... got the right overdraft account';

$checking->withdraw( 50 );
is $checking->balance, 50, '... got the checking balance we expected';
is $savings->balance, 350, '... got the savings balance we expected';

$checking->withdraw( 200 );
is $checking->balance, 0, '... got the checking balance we expected';
is $savings->balance, 200, '... got the savings balance we expected';

done_testing;


