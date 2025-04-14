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
    no = 0,
    yes = 1,
    random = -1,
}

struct Context
{
    float balance, payout;
    int betAmount;
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
        balance: 100,                   // initial balance
        payout: 1,                      // percentage payout (1 == 100%)
        betAmount: 1,                   // bet size
        betAction: BetType.yes,      // start buy randomly choosing yes/no
    );

    // run backtest
    float netProfit = 0;
    int n_yes, n_no, n_wins, n_looses;
    auto prev = df[0];
    foreach (i, current; df)
    {
        if (!i) continue;               // skip the first row just to have something before the start of simulation
        if (context.balance <= 0) break;// stop trading once the account is blown up

        // bet action
        auto action = context.betAction == BetType.random ? uniform!"[]"(0, 1).to!BetType : context.betAction;
        auto priceDiff = current.open - prev.close;
        if (action == BetType.yes)
        {
            n_yes++;
            if (priceDiff > 0)
            {
                n_wins++;
                context.balance += context.payout * context.betAmount;
                netProfit += context.payout * context.betAmount;
            }
            else 
            {
                n_looses++;
                context.balance -= context.betAmount;
                netProfit -= context.betAmount;
            }
        }
        else
        {
            n_no++;
            if (priceDiff < 0)
            {
                n_wins++;
                context.balance += context.payout * context.betAmount;
                netProfit += context.payout * context.betAmount;
            }
            else 
            {
                n_looses++;
                context.balance -= context.betAmount;
                netProfit -= context.betAmount;
            }
        }

        // log
        writefln(
            "%12s ==> balance: %5s | net profit: %5s | n_wins: %5s | n_losses: %5s", 
            current.date, context.balance, netProfit, n_wins, n_looses,
        );

        prev = current;
    }
}

