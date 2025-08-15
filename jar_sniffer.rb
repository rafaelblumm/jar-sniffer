require 'optparse'

# Decompile JARs and search for hard-coded secrets
class JarSniffer
  
  # External dependencies directory
  LIB_DIR = File.join(File.dirname(__FILE__), 'lib').freeze

  # Creates new JarSniffer instance. If dependencies path is not informed, searches in ./lib directory
  # @param vineflower_path [String] Vineflower decompiler path
  # @param trufflehog_path [String] Trufflehog scanner path
  # @throws [StandardError] If required dependencies were not found
  def initialize(vineflower_path = nil, trufflehog_path = nil)
    deps = {}
    deps[:vineflower] = vineflower_path if vineflower_path
    deps[:trufflehog] = trufflehog_path if trufflehog_path
    if deps.size != 2
      deps = search_libs.merge(deps)
      raise StandardError, 'Required dependencies not found' if deps.size != 2
    end

    @vineflower_path = deps[:vineflower]
    @trufflehog_path = deps[:trufflehog]
  end

  # Decompile JAR and search for hard-coded secrets
  # @param jar_path [String] Target JAR path
  # @param output_file [String | nil] File path to log secrets found. Outputs to stdout if `nil`
  # @param output_as_json [Boolean] If should generate output in JSON format
  def scan(jar_path, output_file: nil, output_as_json: false)
    jar_stem = File.basename(jar_path, File.extname(jar_path))
    target_dir = File.join(Dir.pwd, '.decompiled', jar_stem)

    decompile(jar_path, target_dir)
    scan_for_secrets(target_dir, output_file: output_file, as_json: output_as_json)
  end

  private

  # Search for dependendencies (Vineflower and Trufflehog) in ./lib directory
  # @return [Hash<Symbol, String>] Hash with each dependency and its path. Empty if not found
  # @throws [StandardError] If ./lib directory does not exist
  def search_libs
    raise StandardError, "Dependencies directory does not exist: #{LIB_DIR}" unless File.exist?(LIB_DIR)

    deps = {}
    files = Dir[File.join(LIB_DIR, '*')].select { |f| File.file?(f) }
    files.each do |path|
      filename = File.basename(path)
      if /.*vineflower.*\.jar/i.match?(filename)
        deps[:vineflower] = path
      elsif /.*trufflehog.*/i.match?(filename) && File.executable?(path)
        deps[:trufflehog] = path
      end
    end

    deps
  end

  # Decompile jar
  # @param jar_path [String] JAR to decompile
  # @param target_dir [String] Directory to store decompiled jar
  def decompile(jar_path, target_dir)
    cmd = "java -jar #{@vineflower_path} --folder --log-level=warn #{jar_path} #{target_dir}"
    puts
    puts "Decompiling JAR #{jar_path}"
    puts "  > #{cmd}"
    puts `#{cmd}`
  end

  # Analyze decompiler jar for secrets
  # @param project_dir [String] Analyzed project's directory
  # @param output_file [String | nil] File path to log secrets found. Outputs to stdout if `nil`
  # @param output_as_json [Boolean] If should generate output in JSON format
  def scan_for_secrets(project_dir, output_file: nil, as_json: false)
    cmd = "#{@trufflehog_path} filesystem \"#{project_dir}\" --no-update"
    cmd << ' -j' if as_json

    puts
    puts "Scanning secrets in #{project_dir}"
    puts "  > #{cmd}"
    output = `#{cmd}`
    if output_file.nil?
      puts output
      return
    end

    File.open(output_file, 'w') { |file| file.write(output) }
    puts "Output in #{output_file}"
  end

end

# Run script
def run
  args = parse_cmdline
  JarSniffer.new.scan(args[:jar], output_file: args[:output], output_as_json: args[:json])
end

# Parse command line args
# @return [Hash<Symbol, Any>] Parsed args
# @throws [ArgumentError] If informed arg is invalid
def parse_cmdline
  args = {
    jar: nil,
    output: nil,
    json: false
  }
  OptionParser.new do |opts|
    opts.banner = "jar-sniffer: Find hard-coded secrets in compiled JARs\n" \
                  "             Powered by Vineflower Java decompiler and Trufflehog scanner\n\n"
    opts.on('-f', '--jar=FILE', 'Analyzed JAR path')
    opts.on('-o', '--output=FILE', 'Results output file')
    opts.on('-j', '--json', 'Show results as JSON')

    if ARGV.empty?
      puts opts
      exit 1
    end
  end.parse!(into: args)
  raise ArgumentError, "Jar file must exist: #{args[:jar]}" unless File.exist?(args[:jar])
  raise ArgumentError, "Jar must be a file: #{args[:jar]}" unless File.exist?(args[:jar])

  args
end

run if __FILE__ == $PROGRAM_NAME
