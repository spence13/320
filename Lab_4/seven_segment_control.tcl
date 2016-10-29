restart

isim force add clk 1 -value 0 -time 10 ns -repeat 20 ns
put blank 0000
run 1000ns
put blank 0001
run 280ns

put blank 0000
run 1000ns
put blank 0010
run 280ns

put blank 0000
run 1000ns
put blank 0100
run 280ns

put blank 0000
run 1000ns
put blank 1000
run 280ns


put data_in 0000000000001111
run 1300ns

put data_in 0000111100000000
run 1300ns

put dp_in 0001
run 1300ns

put dp_in 0101
run 1300ns