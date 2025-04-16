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
    float[string] stats = ["netProfit": 0, "wins": 0, "losses": 0];

    // run backtest
    writefln(
        "%5s;%12s;%10s;%10s;%10s;%10s;%7s;%10s;%10s;%10s;%10s",
        "step", "date", "open", "close", "bet", "betAmount", "result", "balance", "netProfit", "wins", "losses"
    );
    bool betLost = false;
    immutable betActionOriginal = context.betAction;
    immutable betAmountOriginal = context.betAmount;
    foreach (i, price; df)
    {
        // stop trading once the account is blown up
        if (context.balance <= 0) break;

        // bet action
        auto bet = context.betAction == BetType.random ? uniform!"[]"(0, 1).to!BetType : context.betAction;
        auto priceDiff = price.close - price.open;
        if (bet == BetType.up) // we bet up, price will increase
        {
            if (priceDiff > 0) // won
            {
                // adjust balance
                auto payoutAmount = context.payout * context.betAmount;
                context.balance += payoutAmount;

                // adjust stats
                stats["netProfit"] += payoutAmount;
                stats["wins"] += 1;
                betLost = false;
            }
            else // lost
            {
                // adjust balance
                auto payoutAmount = context.betAmount;
                context.balance -= payoutAmount;

                // adjust stats
                stats["netProfit"] -= payoutAmount;
                stats["losses"] += 1;
                betLost = true;
            }
        }
        else // we bet down, price will decrease
        {
            if (priceDiff < 0) // won
            {
                // adjust balance
                auto payoutAmount = context.payout * context.betAmount;
                context.balance += payoutAmount;

                // adjust stats
                stats["netProfit"] += payoutAmount;
                stats["wins"] += 1;
                betLost = false;
            }
            else // lost
            {
                // adjust balance
                auto payoutAmount = context.betAmount;
                context.balance -= payoutAmount;

                // adjust stats
                stats["netProfit"] -= payoutAmount;
                stats["losses"] += 1;
                betLost = true;
            }
        }

        // log
        writefln(
            "%5s;%12s;%10.1f;%10.1f;%10s;%10.1f;%7s;%10.1f;%10.1f;%10s;%10s",
            i, price.date.to!string, price.open, price.close,
            bet, context.betAmount, betLost ? "lost" : "won", context.balance,
            stats["netProfit"], stats["wins"], stats["losses"],
        );

        // martingale strategy: keep the last bet, double the last position, reset upon winning
        if (betLost)
        {
            context.betAction = bet; // keep our last position
            context.betAmount *= 2;  // double it every time we loose
        }
        else // reset upon winning
        {
            context.betAction = betActionOriginal;
            context.betAmount = betAmountOriginal;
        }
    }
}
