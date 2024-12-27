# PC SleepTimers

Sets some sleep defaults according to the CSV file.

- These settings are defaults that can be adjusted by the user
- Company policy settings will override these settings.
- Time limits are in minutes.  0 means no limit.
- Hibernate limits are always 1 minute longer than sleep limits.

To check settings, copy the line below, open a CMD and paste (Or press Win+R and paste)
`control /name Microsoft.PowerOptions /page pagePlanSettings`

## CSV file (adjust defaults as needed)

 `PC SleepTimers Settings.csv`

```text

   display_battery: 5
     sleep_battery: 10

display_plugggedin: 10
  sleep_plugggedin: 30
```
