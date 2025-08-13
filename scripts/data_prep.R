# Data prep ----

# + File names ----

# electricity meter
fnam_em <- file.path("data", "electricity_meter.csv")

# power station
fnam_ps_daily <- list.files(file.path("data", "ps_daily"), full.names = TRUE)
fnam_ps_detail <- list.files(file.path("data", "ps_detail"), full.names = TRUE)

# + Import data ----

# ++ electricity measure ----
df_em <- read.csv(fnam_em) %>% 
  as_tibble() %>% 
  mutate(
    dt    = as.Date(dt, format = "%Y-%m-%d"),
    dttm  = as.POSIXct(paste(dt, tm), format = "%Y-%m-%d %H:%M"),
    aux   = as.double(dttm) / (3600 * 24),
    tdif  = aux - lag(aux),
    usage = kwh - lag(kwh),
    avgu  = usage / tdif
  ) %>% 
  fill(avgu, .direction = "up")

# ++ power station ----
# +++ daily data ----
df_ps_daily <- 
  map_df(
    fnam_ps_daily,
    .f = \(f) {
      #-- f <- fnam_ps_daily[1]
      read_xlsx(f) %>% 
        select(dt = 2, prod = 4) %>% 
        mutate(
          dt   = as.Date(dt, format = "%Y/%m/%d"),
          prod = as.double(prod)
        ) %>% 
        select(dt, prod)
    }
  ) %>% 
  mutate(month = factor(months(dt), levels = month.name))

# +++ 5-min data ----
df_ps_detail <- 
  map_df(
    fnam_ps_detail,
    .f = \(f) {
      #-- f <- fnam_ps_detail[1]
      read_xlsx(f) %>% 
        select(dttm = 2, prod = 4) %>% 
        mutate(
          dt   = word(dttm) %>% as.Date(format = "%Y/%m/%d"),
          tm   = word(dttm, start = 2) %>% 
            as.difftime(format = "%H:%M", unit = "hours"),
          dttm = as.POSIXct(dttm),
          prod = as.double(prod)
        ) %>% 
        select(dttm, dt, tm, prod)
    }
  )

# + Process data ----

# ++ calculate summary stats of 5-min data by interval
df_ps_detail_sum <- 
  df_ps_detail %>% 
  summarise(
    nrec = n(),
    nvld = sum(!is.na(prod)),
    nmis = sum(is.na(prod)),
    qrt0 = quantile(prod, prob = 0, na.rm = TRUE),
    qrt1 = quantile(prod, prob = .25, na.rm = TRUE),
    qrt2 = quantile(prod, prob = .5, na.rm = TRUE),
    qrt3 = quantile(prod, prob = .75, na.rm = TRUE),
    qrt4 = quantile(prod, prob = 1, na.rm = TRUE),
    .by = tm
  ) %>% 
  arrange(tm) %>% 
  pivot_longer(cols = starts_with("qrt")) %>% 
  mutate(
    tm   = as.numeric(tm),
    name = factor(
      name,
      levels = paste0("qrt", 0:4),
      labels = c("Min", "25%", "50%", "75%", "Max")
    )
  )
