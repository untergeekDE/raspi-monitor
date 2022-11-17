Kleiner Health-Monitor für den Raspi. Dient dazu, die üblichen R-Tools auch auf dem Heim-Bastelserver zum Laufen zu bringen.

# Was das Skript tut

- Lade die nötigen Bibliotheken
- Lies die "Gesundheitsdaten" des Raspi mit Systembefehlen
- Schreibe sie in einen CSV-Logfile
- Mach ein wenig Logfile-Management (zu große Files archivieren und löschen)
- Gib zwei Grafiken in Datawrapper aus

## Erhobene Systemdaten

kommen außer der Temperatur aus Linux-Standardbefehlen:

- Systemtemperatur über ```vcgencmd measure_temp```
- System- und SD-Karten-Auslastung über ```vmstat``` (vgl. [Ubuntu-Wiki](https://wiki.ubuntuusers.de/vmstat/))
- Festplatten- (also: SD-Karten-)Platz über ```df```

## Die Ausgabedaten

- [Tabelle der aktuellen Systemdaten](https://www.datawrapper.de/_/tegVD/)
- [Verlaufskurve Auslastung, Temperatur, Plattenplatz in den letzten 24h](https://www.datawrapper.de/_/tegVD/)
