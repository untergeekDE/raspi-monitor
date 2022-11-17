############### raspi_health.R ##################

# Gehe davon aus, dass das Paket pacman installiert ist - 
# die Funktion p_load installiert ggf. fehlende Pakete von CRAN nach und lädt sie.

pacman::p_load(dplyr)
pacman::p_load(tidyr)
pacman::p_load(stringr)
pacman::p_load(readr)
pacman::p_load(lubridate)

library(DatawRappr)
# pacman::p_load_gh("munichrocker/DatawRappr")

#---- Keys lesen ----
# Keys liegen wie immer in einem user-Verzeichnis. 

#---- Funktionen zum Extrahieren der Health-daten

log_fname <- "logs/health_log.csv"


get_temperature_df <- function() {
  # Ruf die Systemfunktion zur Temperaturmessung auf und lies den ausgegebenen Text ein
  temp_str <- system("vcgencmd measure_temp", intern=TRUE)
  # Mach ein df mit einer Zeile und einer Spalte draus - lässt sich leichter joinen
  temperatur <- temp_str %>% 
    str_extract("[0-9\\.]+") %>% 
    as.numeric()
  return(tibble(temperatur = temperatur))
}

get_proc_usage_df <- function() {
  # Ruf die Systemfunktion zur Prozessorauslastung auf - 5 Sekunden lang - 
  # und errechne Mittelwerte. 
  #
  # Rufe vmstat 5x im Abstand von 1 Sekunde auf...
  # ...mit Parameter -a, der statt buff/cache die aktiven/inaktiven
  # Mempages anzeigt. 
  vmstat_str <- system("vmstat -a 1 5",intern = TRUE)
  # ... verwandle den Output in ein df und errechne dann Durchschnitte. 
  # Erste Zeile enthält einen Tabellenkopf; überspringen.
  # Setze Lokalisierung in Deutsch voraus.
  vmstat_df <- read_table(vmstat_str, skip = 1) %>% 
    summarize(
      procs_in_runtime = round(mean(r), digits = 1),
      procs_blocked = round(mean(b), digits = 1),
      mem_vm = round(mean(swpd)),
      mem_free = round(mean(frei)),
      mem_inact = round(mean(inakt)),
      mem_act = round(mean(aktiv)),
      disk_read = round(mean(bi)),
      disk_write = round(mean(bo)),
      proc_interrupts = round(mean(`in`)),
      contexts = round(mean(cs)),
      cpu_user = round(mean(us), digits = 1),
      cpu_system = round(mean(sy), digits = 1),
      cpu_idle = round(mean(id + wa + st), digits = 1)
    )
  return(vmstat_df)
}

get_disk_usage_df <- function() {
  # Ruf die Systemfunktion zur Festplatten- und Speicher-Nutzung auf.
  vmstat_str <- system("df",intern = TRUE)
  vmstat_df <- read_table(vmstat_str, skip = 1, col_names = FALSE) %>% 
    rename(
      blocks = 2, 
      used = 3, 
      free = 4,
      mnt = 6)  %>% 
    filter(mnt == "/") %>%
    select(blocks, used, free) %>% 
    mutate(free_percent = round(free / blocks * 100, 1))
    
  return(vmstat_df)
}

#---- main ----
#
# Ist dafür gedacht, alle 5 Minuten aufgerufen zu werden. 

# API-Key für Datawrapper? 

# Baue eine neue Tabellenzeile
stats_df <- get_temperature_df() %>%
  mutate(zeitstempel = now()) %>%
  # Zeitstempel nach vorn
  relocate(zeitstempel) %>% 
  bind_cols(get_proc_usage_df()) %>% 
  bind_cols(get_disk_usage_df()) 

# API-Key für Datawrapper holen; Grafiken updaten 
# Gibt es eine Key-Datei? Schreib sie ins .Renviron.
if (file.exists("~/key/dw.key")) {
  handle <- file("~/key/dw.key")
  dw_key <- readLines(handle, n = 1)
  close(handle)
  datawrapper_auth(dw_key, overwrite = T)
  # Schlüsseldatei löschen - DW-Key bleibt im Environment. 
  file.remove("~/key/dw.key")
}

dw_data_to_chart(stats_df,"Y5843")
dw_edit_chart("Y5843",title=stats_df$zeitstempel)
dw_publish_chart("Y5843")

# Logdatei fortschreiben
if (!dir.exists("logs")) dir.create("logs")
if (file.exists(log_fname)) {
  updated_df <- read_csv(log_fname) %>% 
    bind_rows(stats_df) %>% 
    # Hebe nur die letzten 28 Tage auf
    filter(zeitstempel > (now() - days(28)))
} else {
  updated_df <- stats_df
}
write_csv(updated_df,log_fname)

# Verlaufsgrafik letzte 24 Stunden
dw_data_to_chart(updated_df %>% 
                   filter(zeitstempel > (stats_df$zeitstempel - hours(24))),
                                         "tegVD")
dw_edit_chart("tegVD",title=stats_df$zeitstempel)
dw_publish_chart("tegVD")

cat("Fertig.")