# Corona
(in czech)
Analyzátor záznamů osob s prokázanou nákazou koronavirem způsobujícím onemocnění COVID-19

## Usage
```bash
corona \[-h\] \[FILTERS] \[COMMAND\] \[LOG \[LOG2 \[...\]\]
```

## Detailed description [CZ]
COMMAND může být jeden z:<br />
**infected** — spočítá počet nakažených.<br />
**merge** — sloučí několik souborů se záznamy do jednoho, zachovávající původní pořadí (hlavička bude ve výstupu jen jednou).<br />
**gender** — vypíše počet nakažených pro jednotlivá pohlaví.<br />
**age** — vypíše statistiku počtu nakažených osob dle věku (bližší popis je níže).<br />
**daily** — vypíše statistiku nakažených osob pro jednotlivé dny.<br />
**monthly** — vypíše statistiku nakažených osob pro jednotlivé měsíce.<br />
**yearly** — vypíše statistiku nakažených osob pro jednotlivé roky.<br />
**countries** — vypíše statistiku nakažených osob pro jednotlivé země nákazy (bez ČR, tj. kódu CZ).<br />
**districts** — vypíše statistiku nakažených osob pro jednotlivé okresy.<br />
**regions** — vypíše statistiku nakažených osob pro jednotlivé kraje.<br />
FILTERS může být kombinace následujících (každý maximálně jednou):<br />
**-a** DATETIME — after: jsou uvažovány pouze záznamy PO tomto datu (včetně tohoto data). DATETIME je formátu YYYY-MM-DD.<br />
**-b** DATETIME — before: jsou uvažovány pouze záznamy PŘED tímto datem (včetně tohoto data).<br />
**-g** GENDER — jsou uvažovány pouze záznamy nakažených osob daného pohlaví. GENDER může být M (muži) nebo Z (ženy).<br />
**-s** [WIDTH] u příkazů gender, age, daily, monthly, yearly, countries, districts a regions vypisuje data ne číselně, ale graficky v podobě histogramů.<br />
**-h** — vypíše nápovědu s krátkým popisem každého příkazu a přepínače.<br />

# File example
```csv
id,datum,vek,pohlavi,kraj_nuts_kod,okres_lau_kod,nakaza_v_zahranici,nakaza_zeme_csu_kod,reportovano_khs
3975d2d8-308e-456c-bc1c-63696e2fe42b,2020-03-06,61,Z,CZ010,CZ0100,1,IT,1
923c92e3-8a3a-48d1-99e2-738bb8a36e18,2020-04-21,0,M,CZ080,CZ0802,,,1
cd40fcf1-4460-4738-819f-45c97f818736,2020-04-21,57,M,CZ020,CZ020A,,,1
f08b5f36-b01b-4de4-af27-74a46550a640,2020-04-21,51,Z,CZ080,CZ0806,,,1
1fe00b35-7916-475e-a2d0-a654fa37626f,2020-04-21,27,Z,CZ042,CZ0423,,,1
c93c218f-e655-4374-8185-fe9a9e3c2796,2020-04-21,33,M,CZ041,CZ0411,,,1
4dd6c43b-8113-4563-90fc-9c549ed45dbe,2020-04-21,28,Z,CZ041,CZ0412,,,1
f3979021-91c2-43df-b92e-3755cabf84d6,2020-04-21,82,M,CZ080,CZ0804,,,1
7a864108-1436-4ee0-990f-a5982622255b,2020-04-21,72,M,CZ041,CZ0411,,,1
04d90f24-22d2-4277-b94c-695d71bba500,2020-04-21,52,M,CZ010,CZ0100,,,1
a77e530e-1f8a-4221-a7c4-218405554853,2020-04-21,88,M,CZ071,CZ0715,,,1
04d90f24-22d2-4277-b94c-695d71bba500,2020-04-21,52,M,CZ010,CZ0100,,,1
a77e530e-1f8a-4221-a7c4-218405554853,2020-043-21,88,M,CZ071,CZ0715,,,1
8492510d-309e-45c7-bdec-e58eb3607ac3,2020-04-21,56,M,CZ080,CZ0804,,,1
d0886572-e1b3-4573-8cb3-77164d57a7db, 2020-04-21 ,45,Z,CZ064,CZ0647,1,AT,1
7af90a68-c2c9-4d70-bec5-21d024d8de77,2020-04-21,56,M,CZ080,CZ0805,,,1
d0e1878c-ab05-47ac-89f8-4c7dadfcd7d0,2020-04-21,54,Z,CZ080,CZ0802,,,1
```

## Project is for Operation System courses
You can learn more abou this course [here](https://www.fit.vut.cz/study/course/244864/.cs)
