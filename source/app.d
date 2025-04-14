module app;

import std.csv;
import std.conv;
import std.file;
import std.stdio;
import std.string;
import std.datetime;

struct Layout
{
	Date date;
	float price, open, high, low;
	string vol, change;
}

string sanitizeCsv(string csv) {
    import std.regex : regex, replaceAll;

    // this regex finds numbers like "4,166.82" and removes the comma inside quotes
    auto numberWithCommas = regex(`"(\d{1,3}),(\d{3}\.\d+)"`);
    return csv
		.replaceAll(numberWithCommas, `"$1$2"`)
		.replace("Date", "date")
		.replace("Price", "price")
		.replace("Open", "open")
		.replace("High", "high")
		.replace("Low", "low")
		.replace("Vol.", "vol")
		.replace("Change %", "change")
		.replace("Date", "date")
		.replace("\"", "");
}

void main(string[] args)
{
	if (args.length < 2)
	{
		writeln("USAGE: ./binary_options CSVFILE");
		return;
	}

	auto data = readText(args[1]).sanitizeCsv;
	Layout[] df;
	foreach (i, line; data.splitLines)
	{
		if (!i) continue;
		auto p = line.split(",");
		auto d = p[0].split("/");
		df ~= Layout(
			Date(d[2].to!int, d[0].to!int, d[1].to!int),
			p[1].to!float,
			p[2].to!float,
			p[3].to!float,
			p[4].to!float,
			p[5],
			p[6],
		);
	}
	df.writeln;
	// auto df = csvReader!Layout(data, ',', '"', true);
	// writeln(df);
}
