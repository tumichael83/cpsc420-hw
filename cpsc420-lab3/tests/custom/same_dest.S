

#include "parc-macros.h"

li    $2,   0x00000000;
li    $3,   0x00000001;

addu  $4,   $2, $3;
addu  $4,   $2, $0;

TEST_CHECK_EQ( $4, 0x00000000 );