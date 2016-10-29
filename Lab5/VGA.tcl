restart

isim force add clk 1 -value 0 -time 20 ns -repeat 40 ns

put rst 1
run 2us

put rst 0
run 17ms
