
restart

#turn on all the segments
put sw 00000001
put btn 1000
run 100ns

#turn off all the segments
put sw 00000001
put btn 0100
run 100ns

#turn on number on lower four switches
put sw 00000011
put btn 0000
run 100ns

put sw 00001000
put btn 0000
run 100ns

#turn on number on upper four switches
put sw 11000001
put btn 0001
run 100ns

put sw 11010101
put btn 0001
run 100ns

#lower XOR upper
put sw 01000011
put btn 0010
run 100ns

put sw 00100001
put btn 0010
run 100ns

#rotate lower four by two
put sw 00000001
put btn 0011
run 100ns

put sw 00000011
put btn 0011
run 100ns