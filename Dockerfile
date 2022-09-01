# Build the database of archives
FROM perl:5 AS build

RUN apt-get update && apt-get install -y \
	sqlite3 \
	&& rm -rf /var/lib/apt/lists/*

RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'DBD::SQLite')"

WORKDIR /app
COPY . .

RUN ./bin/download_index.sh && \
	sqlite3 archives.db < ./sql/create_database.sql

RUN ./bin/parse_index.pl allfiles.txt archives.db
