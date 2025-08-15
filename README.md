# JAR Sniffer

## Find hard-coded secrets in compiled JARs

This tool decompiles a target JAR and scans the decompiled project for
hard-coded secrets and credentials

Useful when pentesting a Java application.

### Downloading dependencies

This tool relies on Vineflower decompiler and Trufflehog secrets scanner.
You can download them on their respective GitHub release tab:

- [Vineflower on GitHub](https://github.com/Vineflower/vineflower/releases)
- [Trufflehog on Github](https://github.com/trufflesecurity/trufflehog/releases)

After that, copy Vineflower's JAR and Trufflehog's binary on a `lib` directory.
Your project structure should look like this:

```plaintext
root
    \
    +-- lib
    |   \
    |    +-- vineflower-1.11.1.jar
    |    +-- trufflehog
    +-- jar_sniffer.rb
```

### Using from the command line

| Short | Long       | Type    | Description                            |
|-------|------------|---------|----------------------------------------|
| `-f`  | `--jar`    | String  | JARs path to be decompiled and scanned |
| `-o`  | `--output` | String  | Scanned secrets output file path       |
| `-j`  | `--json`   | Boolean | Output result as JSON                  |

Command-line example:

```bash
ruby jar_sniffer.rb -f /path/to/your/analized-jar.jar -o ./output.json -j
```

### Integrating on your own Ruby scripts

The class `JarSniffer` was implemented in a way that allows developers and security
professionals to develop scripts to perform multiple analysis and automations.

Just import it and it's ready to go!

```ruby
require 'jar_sniffer'

jar_path = '/path/to/your/analized-jar.jar'
JarSniffer.new.scan(jar_path, output_file: './output.json', as_json: true)
```
