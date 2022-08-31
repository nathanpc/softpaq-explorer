--- create_database.sql
--- Creates the database to store the SoftPAQ collection.
---
--- Author: Nathan Campos <nathan@innoveworkshop.com>

CREATE TABLE archives (
	id         INTEGER PRIMARY KEY AUTOINCREMENT,
	exename    TEXT NOT NULL,
	orig_url   TEXT NOT NULL,
	size       TEXT NOT NULL,
	rel_date   TEXT,
	title      TEXT,
	version    TEXT,
	language   TEXT,
	products   TEXT,
	os         TEXT,
	supersedes TEXT
);
