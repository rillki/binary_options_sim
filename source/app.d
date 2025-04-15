module app;

import std.csv;
import std.conv;
import std.file;
import std.stdio;
import std.regex;
import std.array;
import std.random;
import std.string;
import std.datetime;
import std.algorithm;

struct MyDate
{
    Date date;
    alias this = date;
    this(in string d)
    {
        this.date = Date.fromISOExtString(d);
    }
}

struct Layout
{
    MyDate date;
    float open, high, low, close;
}

enum BetType: int
{
    up = 0,      // bet price will go up
    down = 1,    // bet price will go down
    random = -1, // randomize what we should bet on from options above
}

struct Context
{
    // your trade balance (how much money your have in your account)
    float balance;

    // payout rate between (0, 1]
    float payout;

    // how much to bet on a trade
    int betAmount;

    // what bet should be made
    BetType betAction;
}

// WIP
void main(string[] args)
{
    if (args.length < 2)
    {
        writeln("USAGE: ./binary_options file.csv");
        return;
    }

    // process csv
    auto df = args[1]
        .readText
        .csvReader!Layout(["Date", "Open", "High", "Low", "Close"])
        .array;

    // init
    auto context = Context(
        balance:    100,
        payout:     1,
        betAmount:  1,
        betAction:  BetType.random,
    );

    // run backtest
    float[string] stats = ["netProfit": 0, "betUp": 0, "betDown": 0, "wins": 0, "losses": 0];
    foreach (price; df)
    {
        // stop trading once the account is blown up
        if (context.balance <= 0) break;

        // bet action
        auto bet = context.betAction == BetType.random ? uniform!"[]"(0, 1).to!BetType : context.betAction;
        auto priceDiff = price.close - price.open;
        if (bet == BetType.up) // we bet up, price will increase
        {
            stats["betUp"] += 1;
            if (priceDiff > 0) // won
            {
                // adjust balance
                auto payoutAmount = context.payout * context.betAmount;
                context.balance += payoutAmount;

                // adjust stats
                stats["netProfit"] += payoutAmount;
                stats["wins"] += 1;
            }
            else
            {
                // adjust balance
                auto payoutAmount = context.betAmount;
                context.balance -= payoutAmount;

                // adjust stats
                stats["netProfit"] -= payoutAmount;
                stats["losses"] += 1;
            }
        }
        else // we bet down, price will decrease
        {
            stats["betDown"] += 1;
            if (priceDiff < 0) // won
            {
                // adjust balance
                auto payoutAmount = context.payout * context.betAmount;
                context.balance += payoutAmount;

                // adjust stats
                stats["netProfit"] += payoutAmount;
                stats["wins"] += 1;
            }
            else
            {
                // adjust balance
                auto payoutAmount = context.betAmount;
                context.balance -= payoutAmount;

                // adjust stats
                stats["netProfit"] -= payoutAmount;
                stats["losses"] += 1;
            }
        }

        // log
        writefln(
            "%12s ==> bet: %5s | balance: %5s | net profit: %5s | wins: %5s | losses: %5s",
            price.date, bet, context.balance, stats["netProfit"], stats["wins"], stats["losses"],
        );
    }
}
