# ============================================================================
#  Mod Compatibility Checker for KIF Multiplayer + EBDX
#  Place this file in the Mods/ folder and run via check_compat.bat
# ============================================================================

require "ripper"

# ---------------------------------------------------------------------------
#  RbParser — extracts definitions from a single .rb file using regex
# ---------------------------------------------------------------------------
class RbParser
  Definition = Struct.new(:kind, :scope, :name, :target, :file, :line, :wrapper)
  # kind:   :class, :module, :method, :alias
  # scope:  the enclosing class/module (e.g. "PokeBattle_Battle") or "(global)"
  # name:   the defined name (method name, alias new name, class/module name)
  # target: for aliases, the original method being aliased; nil otherwise
  # file:   source file path
  # line:   line number
  # wrapper: true when an alias is paired with a later method definition of the
  #          same target in the same scope/file, indicating alias-chain wrapping.

  class << self
    def parse(filepath)
      source = File.read(filepath, encoding: "utf-8")
      sexp = Ripper.sexp(source)
      return [] if sexp.nil?

      defs = []
      walk(sexp, defs, filepath, [], false)
      mark_wrappers(defs)
      defs
    rescue
      []
    end

    private

    def walk(node, defs, filepath, scope_stack, singleton_context)
      return if node.nil?

      if statement_list?(node)
        node.each do |child|
          walk(child, defs, filepath, scope_stack, singleton_context)
        end
        return
      end

      return unless node.is_a?(Array)

      case node[0]
      when :program
        walk(node[1], defs, filepath, scope_stack, singleton_context)
      when :bodystmt
        walk(node[1], defs, filepath, scope_stack, singleton_context)
      when :module
        raw_name, line = const_name_and_line(node[1])
        return if raw_name.nil?
        full_name = qualify_scope(scope_stack, raw_name)
        defs << Definition.new(:module, current_scope(scope_stack), full_name, nil, filepath, line, false)
        walk(node[2], defs, filepath, scope_stack + [full_name], false)
      when :class
        raw_name, line = const_name_and_line(node[1])
        return if raw_name.nil?
        full_name = qualify_scope(scope_stack, raw_name)
        defs << Definition.new(:class, current_scope(scope_stack), full_name, nil, filepath, line, false)
        walk(node[3], defs, filepath, scope_stack + [full_name], false)
      when :sclass
        self_context = singleton_self_receiver?(node[1]) || singleton_context
        walk(node[2], defs, filepath, scope_stack, self_context)
      when :def
        name, line = ident_name_and_line(node[1])
        return if name.nil?
        qualified = singleton_context ? "self.#{name}" : name
        defs << Definition.new(:method, current_scope(scope_stack), qualified, nil, filepath, line, false)
      when :defs
        name, line = ident_name_and_line(node[3])
        return if name.nil?
        defs << Definition.new(:method, current_scope(scope_stack), "self.#{name}", nil, filepath, line, false)
      when :alias
        new_name, line = symbol_name_and_line(node[1])
        old_name, = symbol_name_and_line(node[2])
        return if new_name.nil? || old_name.nil?
        prefix = singleton_context ? "self." : ""
        defs << Definition.new(:alias, current_scope(scope_stack), "#{prefix}#{new_name}", "#{prefix}#{old_name}", filepath, line, false)
      when :command
        return unless alias_method_command?(node)
        new_name, old_name, line = alias_method_names(node)
        return if new_name.nil? || old_name.nil?
        prefix = singleton_context ? "self." : ""
        defs << Definition.new(:alias, current_scope(scope_stack), "#{prefix}#{new_name}", "#{prefix}#{old_name}", filepath, line, false)
      else
        node.each do |child|
          walk(child, defs, filepath, scope_stack, singleton_context) if child.is_a?(Array)
        end
      end
    end

    def mark_wrappers(defs)
      aliases = defs.select { |d| d.kind == :alias }
      methods = defs.select { |d| d.kind == :method }

      methods.each do |method_def|
        wrapper_alias = aliases.any? do |alias_def|
          alias_def.file == method_def.file &&
            alias_def.scope == method_def.scope &&
            alias_def.target == method_def.name &&
            alias_def.line <= method_def.line
        end
        method_def.wrapper = wrapper_alias
      end

      aliases.each do |alias_def|
        wrapped_method = methods.any? do |method_def|
          method_def.file == alias_def.file &&
            method_def.scope == alias_def.scope &&
            method_def.name == alias_def.target &&
            method_def.line >= alias_def.line
        end
        alias_def.wrapper = wrapped_method
      end
    end

    def statement_list?(node)
      node.is_a?(Array) && !node.empty? && !node[0].is_a?(Symbol)
    end

    def current_scope(scope_stack)
      scope_stack.last || "(global)"
    end

    def qualify_scope(scope_stack, raw_name)
      return raw_name if scope_stack.empty?
      return raw_name if raw_name.start_with?("::")
      return "#{scope_stack.last}::#{raw_name}"
    end

    def singleton_self_receiver?(node)
      return false unless node.is_a?(Array)
      return node == [:var_ref, [:@kw, "self", node.dig(1, 2)]] if node[0] == :var_ref && node[1].is_a?(Array)
      return node[0] == :var_ref && node[1][0] == :@kw && node[1][1] == "self"
    end

    def const_name_and_line(node)
      return [nil, 0] unless node.is_a?(Array)

      case node[0]
      when :const_ref
        token = node[1]
        [token[1], token[2][0]]
      when :var_ref
        token = node[1]
        [token[1], token[2][0]]
      when :const_path_ref, :const_path_field
        left_name, left_line = const_name_and_line(node[1])
        right = node[2]
        return [nil, 0] if left_name.nil? || !right.is_a?(Array)
        ["#{left_name}::#{right[1]}", left_line]
      when :top_const_ref
        inner_name, line = const_name_and_line(node[1])
        [inner_name ? "::#{inner_name}" : nil, line]
      else
        [nil, 0]
      end
    end

    def ident_name_and_line(node)
      return [nil, 0] unless node.is_a?(Array)
      return [node[1], node[2][0]] if node[0].to_s.start_with?("@")
      [nil, 0]
    end

    def symbol_name_and_line(node)
      return [nil, 0] unless node.is_a?(Array)

      case node[0]
      when :symbol_literal, :symbol
        symbol_name_and_line(node[1])
      else
        ident_name_and_line(node)
      end
    end

    def alias_method_command?(node)
      ident = node[1]
      return false if !ident.is_a?(Array)
      return false if ident[0] != :@ident || ident[1] != "alias_method"
      args = node[2]
      return false if !args.is_a?(Array) || args[0] != :args_add_block
      values = args[1]
      return values.is_a?(Array) && values.length >= 2
    end

    def alias_method_names(node)
      args = node[2][1]
      new_name, line = symbol_name_and_line(args[0])
      old_name, = symbol_name_and_line(args[1])
      [new_name, old_name, line]
    end
  end
end

# ---------------------------------------------------------------------------
#  Registry — holds all definitions from a set of folders
# ---------------------------------------------------------------------------
class Registry
  attr_reader :classes, :modules, :methods, :aliases, :all_defs

  def initialize
    @classes  = {}  # "ClassName" => [Definition, ...]
    @modules  = {}  # "ModuleName" => [Definition, ...]
    @methods  = {}  # "Scope#method" => [Definition, ...]
    @aliases  = {}  # "Scope#alias_new" => [Definition, ...]
    @all_defs = []
  end

  def load_folder(folder_path)
    return unless Dir.exist?(folder_path)
    load_files(Dir.glob(File.join(folder_path, "**", "*.rb")).sort)
  end

  def load_files(files)
    files.each do |f|
      defs = RbParser.parse(f)
      defs.each { |d| register(d) }
      @all_defs.concat(defs)
    end
  end

  def register(d)
    case d.kind
    when :class
      (@classes[d.name] ||= []) << d
    when :module
      (@modules[d.name] ||= []) << d
    when :method
      key = "#{d.scope}##{d.name}"
      (@methods[key] ||= []) << d
    when :alias
      key = "#{d.scope}##{d.name}"
      (@aliases[key] ||= []) << d
      # Also register the target (old method) as being touched
      tkey = "#{d.scope}##{d.target}"
      (@aliases[tkey] ||= []) << d
    end
  end

  def has_class?(name)
    @classes.key?(name)
  end

  def has_module?(name)
    @modules.key?(name)
  end

  def has_method?(scope, method_name)
    @methods.key?("#{scope}##{method_name}")
  end

  def has_alias_touching?(scope, method_name)
    @aliases.key?("#{scope}##{method_name}")
  end

  def source_label(scope, method_name)
    key = "#{scope}##{method_name}"
    entry = @methods[key]&.first || @aliases[key]&.first
    return nil unless entry
    normalized = entry.file.tr("\\", "/")
    parts = normalized.split("/")
    mods_index = parts.rindex("mods")
    scripts_index = parts.rindex("Scripts")

    if mods_index
      parts[(mods_index + 1)..].join("/")
    elsif scripts_index
      parts[(scripts_index + 1)..].join("/")
    else
      File.basename(entry.file)
    end
  end
end

# ---------------------------------------------------------------------------
#  Comparator — checks mod definitions against the registry
# ---------------------------------------------------------------------------
class Comparator
  Result = Struct.new(:status, :mod_file, :kind, :scope, :name, :detail, :line)
  # status: :compatible, :warning, :not_compatible

  def initialize(registry)
    @registry = registry
  end

  def check(mod_defs)
    results = []
    reopened_scopes = {}

    mod_defs.each do |d|
      case d.kind
      when :class
        if @registry.has_class?(d.name)
          reopened_scopes[d.name] = true
          # Don't add a result yet — methods inside will determine severity
        end

      when :module
        if @registry.has_module?(d.name)
          reopened_scopes[d.name] = true
        end

      when :method
        scope = d.scope
        next if scope == "(def)" || scope == "(global)" && !method_is_global_conflict?(d)

        effective_scope = scope == "(global)" ? "(global)" : scope

        if @registry.has_method?(effective_scope, d.name) ||
           @registry.has_alias_touching?(effective_scope, d.name)
          source = @registry.source_label(effective_scope, d.name)
          if d.wrapper
            detail = "Wraps #{effective_scope}##{d.name} via alias chain"
            detail += " (also modified in #{source})" if source
            results << Result.new(:warning, d.file, :method, effective_scope, d.name, detail, d.line)
          else
            detail = "Redefines #{effective_scope}##{d.name}"
            detail += " (also in #{source})" if source
            results << Result.new(:not_compatible, d.file, :method, effective_scope, d.name, detail, d.line)
          end
        end

      when :alias
        next if d.wrapper
        scope = d.scope
        # Check if the target method (being aliased away) conflicts
        if @registry.has_method?(scope, d.target) ||
           @registry.has_alias_touching?(scope, d.target)
          source = @registry.source_label(scope, d.target)
          detail = "Aliases over #{scope}##{d.target}"
          detail += " (also aliased in #{source})" if source
          results << Result.new(:not_compatible, d.file, :alias, scope, d.name, detail, d.line)
        end
      end
    end

    # Add warnings for class/module reopenings that didn't produce conflicts
    conflicted_scopes = results.select { |r| r.status == :not_compatible }.map(&:scope).uniq
    reopened_scopes.each do |scope_name, _|
      unless conflicted_scopes.include?(scope_name)
        results << Result.new(:warning, mod_defs.first&.file, :class, scope_name, scope_name,
          "Reopens #{scope_name} (also modified by 659/660) — different methods, but test carefully", 0)
      end
    end

    results
  end

  private

  def method_is_global_conflict?(d)
    @registry.has_method?("(global)", d.name) ||
      @registry.has_alias_touching?("(global)", d.name)
  end
end

# ---------------------------------------------------------------------------
#  Reporter — formats and outputs results
# ---------------------------------------------------------------------------
class Reporter
  STATUS_LABELS = {
    compatible:     "[COMPATIBLE]    ",
    warning:        "[WARNING]       ",
    not_compatible: "[NOT COMPATIBLE]"
  }

  STATUS_ICONS = {
    compatible:     "OK",
    warning:        "!!",
    not_compatible: "XX"
  }

  def initialize(output_path)
    @output_path = output_path
    @lines = []
  end

  def out(text = "")
    @lines << text
    puts text
  end

  def report_header
    out "=" * 72
    out "  MOD COMPATIBILITY REPORT"
    out "  Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    out "=" * 72
    out
  end

  def report_scan_info(mp_count, ebdx_count, mod_entries)
    mod_file_count = mod_entries.sum { |entry| entry.files.length }
    out "  Scanned 659_Multiplayer : #{mp_count} files"
    out "  Scanned 660_EBDX        : #{ebdx_count} files"
    out "  Mods found               : #{mod_entries.length}"
    out "  Mod scripts found        : #{mod_file_count}"
    out
    if mod_entries.empty?
      out "  No .rb mod files found in the Mods folder."
      out "  Place your mod .rb files here and re-run."
    end
    out
  end

  def report_mod(mod_label, mod_files, results)
    out "-" * 72
    out "  MOD: #{mod_label} (#{mod_files.length} file#{mod_files.length == 1 ? "" : "s"})"
    out "-" * 72
    mod_files.each do |mod_file|
      out "    - #{mod_file}"
    end
    out

    if results.empty?
      out "  #{STATUS_LABELS[:compatible]} No conflicts detected."
      out
      return :compatible
    end

    worst = :compatible
    # Sort: not_compatible first, then warning
    sorted = results.sort_by { |r| r.status == :not_compatible ? 0 : (r.status == :warning ? 1 : 2) }

    sorted.each do |r|
      worst = :not_compatible if r.status == :not_compatible
      worst = :warning if r.status == :warning && worst != :not_compatible

      line_info = r.line > 0 ? " (line #{r.line})" : ""
      out "  #{STATUS_LABELS[r.status]} #{r.detail}#{line_info}"
    end
    out
    worst
  end

  def report_summary(file_statuses)
    out "=" * 72
    out "  SUMMARY"
    out "=" * 72
    out

    file_statuses.each do |filename, status|
      icon = STATUS_ICONS[status]
      label = status.to_s.upcase.gsub("_", " ")
      out "  [#{icon}] #{filename.ljust(40)} #{label}"
    end
    out
  end

  def report_guidelines
    out "=" * 72
    out "  MODDER GUIDELINES"
    out "=" * 72
    out
    out "  1. Avoid redefining methods already aliased by 659/660."
    out "     Use alias chaining instead of direct overrides."
    out
    out "  2. If you must override a method flagged [NOT COMPATIBLE],"
    out "     alias the current version first:"
    out "       alias my_mod_original_methodName methodName"
    out
    out "  3. Class reopenings flagged [WARNING] are likely OK but"
    out "     test thoroughly with multiplayer, EBDX, and other mods enabled."
    out
    out "  4. New classes/modules with unique names are always safe."
    out
    out "  5. Re-run this checker after updating multiplayer, EBDX, or installed mods."
    out
    out "=" * 72
  end

  def save
    File.write(@output_path, @lines.join("\n"), encoding: "utf-8")
    puts
    puts "  Report saved to: #{@output_path}"
  end
end

# ---------------------------------------------------------------------------
#  Mod discovery helpers
# ---------------------------------------------------------------------------
ModEntry = Struct.new(:label, :files)

def count_ruby_files(folder_path)
  return 0 unless Dir.exist?(folder_path)
  Dir.glob(File.join(folder_path, "**", "*.rb")).length
end

def relative_to_folder(folder_path, file_path)
  folder = File.expand_path(folder_path).tr("\\", "/")
  file = File.expand_path(file_path).tr("\\", "/")
  file.sub(/\A#{Regexp.escape(folder)}\/?/i, "")
end

def collect_mod_entries(mods_folder, self_name)
  entries = []

  top_level_files = Dir.glob(File.join(mods_folder, "*.rb")).sort.reject do |f|
    File.basename(f).downcase == self_name.downcase
  end
  top_level_files.each do |mod_file|
    relative_file = relative_to_folder(mods_folder, mod_file)
    entries << ModEntry.new(File.basename(mod_file), [relative_file])
  end

  Dir.glob(File.join(mods_folder, "*")).sort.each do |entry_path|
    next unless File.directory?(entry_path)

    mod_files = Dir.glob(File.join(entry_path, "**", "*.rb")).sort
    next if mod_files.empty?

    relative_files = mod_files.map { |f| relative_to_folder(mods_folder, f) }
    entries << ModEntry.new(File.basename(entry_path), relative_files)
  end

  entries.sort_by { |entry| entry.label.downcase }
end

def parse_mod_entries(mods_folder, mod_entries)
  mod_entries.each_with_object({}) do |entry, result|
    absolute_files = entry.files.map { |f| File.join(mods_folder, f) }
    defs = absolute_files.flat_map { |file| RbParser.parse(file) }
    result[entry.label] = defs
  end
end

def build_registry(base_defs, other_mod_defs)
  registry = Registry.new
  base_defs.each { |d| registry.register(d) }
  other_mod_defs.each { |defs| defs.each { |d| registry.register(d) } }
  registry
end

# ---------------------------------------------------------------------------
#  Main
# ---------------------------------------------------------------------------
def main
  # Resolve paths relative to this script's location
  script_dir   = File.dirname(File.expand_path(__FILE__))
  project_root = File.expand_path(File.join(script_dir, ".."))
  mp_folder    = File.join(project_root, "Data", "Scripts", "659_Multiplayer")
  ebdx_folder  = File.join(project_root, "Data", "Scripts", "660_EBDX")
  mods_folder  = script_dir
  report_path  = File.join(mods_folder, "compat_report.txt")

  # Build registry from 659 + 660
  base_registry = Registry.new
  base_registry.load_folder(mp_folder)
  mp_count = count_ruby_files(mp_folder)

  base_registry.load_folder(ebdx_folder)
  ebdx_count = count_ruby_files(ebdx_folder)

  # Find mod files (exclude this script itself)
  self_name = File.basename(__FILE__)
  mod_entries = collect_mod_entries(mods_folder, self_name)
  mod_defs = parse_mod_entries(mods_folder, mod_entries)

  # Report
  reporter = Reporter.new(report_path)
  reporter.report_header
  reporter.report_scan_info(mp_count, ebdx_count, mod_entries)

  file_statuses = {}

  mod_entries.each do |mod_entry|
    comparison_registry = build_registry(
      base_registry.all_defs,
      mod_defs.reject { |label, _| label == mod_entry.label }.values
    )
    comparator = Comparator.new(comparison_registry)
    results = comparator.check(mod_defs.fetch(mod_entry.label, []))
    status = reporter.report_mod(mod_entry.label, mod_entry.files, results)
    file_statuses[mod_entry.label] = status
  end

  if mod_entries.any?
    reporter.report_summary(file_statuses)
  end

  reporter.report_guidelines
  reporter.save
end

main
