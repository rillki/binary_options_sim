# Binary options simulation
This is just some simple code for backtesting a few strategies for a friend of mine.

**Implemented**:
* Martingale strategy

## Install
You'll need D programming language compiler to run this code. Download from [here](https://dlang.org). Choose DMD compiler.

## Run
```sh
# clone this repo or download *.zip from github
git clone https://github.com/rillki/binary_options_sim
cd binary_options_sim

# run with `rdmd`
rdmd source/app.d btcusd.csv

# or build with `dub` and run the executable
dub build
./binary_options btcusd.csv
```

You can try modifying the [`Context`](./source/app.d#L37) parameter values:
```d
auto context = Context(
    balance:    100,            // initial balance
    payout:     1,              // payout percentage in case of winning (0; 1]
    betAmount:  1,              // how much to bet per trade
    betAction:  BetType.random, // randomly select value (up, down)
);
```

## LICENSE
All code is licensed under the MIT license.
