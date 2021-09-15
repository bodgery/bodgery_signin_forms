# syntax=docker/dockerfile:1
FROM perl:5.34.0
ADD META.yml /META.yml
RUN cpanm -n --installdeps .
COPY . .

CMD [ "starman", "--listen", ":5001", "app.pl" ]
