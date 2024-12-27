# PC Local Accounts

In the CSV, use the EncryptionKey column to obfuscate the password as follows:  

|Use (without the quote marks)|For This|
| `<Encrypt>`|(with the angle brackets) to interactively enter a key and get the obfuscated password.|
|                    `<Random>`| to generate a random, unique password, different on every computer (pw value is ignored)|
|           `my_encryption_key`| to use this key against an obfuscated password|
|                     `<blank>`| to use the password as-is without obfuscation (not recommended)|

Passwords in CSV are obfuscated but not encrypted (unless `<Random>` is used).  
DELETE AND PURGE THE CSV AFTER RUNNING.  

## CSV file (adjust defaults as needed)

 `PC Local Accounts.csv`

|Username|DisplayName|Description|Groups|EncryptionKey|Password|Comment|
|AdminUser||This pw is randomly generated.|Administrators|<Random>|<Random>|This is a good account to use for your LAPS admin account (it must exist for LAPS to work with it)|

 `PC Local Accounts (To Disable).csv`

 A list of local accounts to disable (if found)  
