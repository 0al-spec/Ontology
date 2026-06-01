#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "yaml"

ROOT = File.expand_path("../../..", __dir__)

API_VERSION = "ontology.specgraph.io/v1alpha1"
KIND = "DomainOntologyPackage"

NAME_RE = /\A[A-Za-z][A-Za-z0-9_]*\z/.freeze
STATE_RE = /\A[a-z][a-z0-9_]*\z/.freeze
CONCEPT_RE = /\A([A-Za-z][A-Za-z0-9_]*|[A-Za-z][A-Za-z0-9_.-]*:[A-Za-z][A-Za-z0-9_]*)\z/.freeze
ID_RE = /\A[a-z][a-z0-9]*(\.[a-z0-9][a-z0-9-]*)+\z/.freeze
NAMESPACE_RE = /\A[a-z][a-z0-9-]*\z/.freeze
VERSION_RE = /\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?\z/.freeze

UNSAFE_KEYS = Set.new(%w[
  eval
  exec
  executable
  expression
  hook
  hooks
  plugin
  plugins
  posthook
  prehook
  script
  scripts
])

UNSAFE_VALUE_RE = /(\$\(|`|<%|eval\(|child_process|subprocess|os\.system|Runtime\.getRuntime)/.freeze
UNSAFE_TAG_RE = /!!(ruby|python|perl|js)|!<.*(ruby|python|perl|js)/i.freeze

VALID_FIXTURES = [
  File.join(ROOT, "SPECS/ontology/examples/examcalc.ontology.yaml"),
  File.join(ROOT, "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml")
] + Dir[File.join(ROOT, "SPECS/ontology/fixtures/valid/*.yaml")].sort

INVALID_FIXTURES = {
  "missing-metadata.yaml" => /metadata\.version/,
  "invalid-inheritance.yaml" => /extends must be scalar string/,
  "unknown-relation-ref.yaml" => /unknown relation domain reference/,
  "unsafe-executable-looking-yaml.yaml" => /unsafe executable-looking/
}.transform_keys { |name| File.join(ROOT, "SPECS/ontology/fixtures/invalid", name) }

def rel(path)
  path.sub("#{ROOT}/", "")
end

def scalar_string?(value)
  value.is_a?(String) && !value.empty?
end

def unknown_keys(hash, allowed, path, errors)
  hash.each_key do |key|
    next if allowed.include?(key)

    errors << "#{path}.#{key} is not allowed"
  end
end

def require_hash(value, path, errors)
  return value if value.is_a?(Hash)

  errors << "#{path} must be an object"
  nil
end

def require_array(value, path, errors)
  return value if value.is_a?(Array)

  errors << "#{path} must be an array"
  nil
end

def require_string(value, path, errors)
  return value if scalar_string?(value)

  errors << "#{path} must be a non-empty string"
  nil
end

def require_key(hash, key, path, errors)
  return hash[key] if hash.key?(key)

  errors << "#{path}.#{key} is required"
  nil
end

def check_pattern(value, pattern, path, errors)
  return unless scalar_string?(value)
  return if value.match?(pattern)

  errors << "#{path} has invalid format"
end

def safe_load_yaml(path)
  content = File.read(path)
  errors = []

  content.each_line.with_index(1) do |line, number|
    if line.match?(UNSAFE_TAG_RE) || line.match?(UNSAFE_VALUE_RE)
      errors << "#{rel(path)}:#{number} contains unsafe executable-looking YAML content"
    end
  end

  data = YAML.safe_load(
    content,
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false
  )

  [data, errors]
rescue Psych::Exception => e
  [nil, errors + ["#{rel(path)} YAML parse error: #{e.message}"]]
end

def scan_unsafe_node(value, path, errors)
  case value
  when Hash
    value.each do |key, child|
      key_text = key.to_s
      if UNSAFE_KEYS.include?(key_text.downcase)
        errors << "#{path}.#{key_text} contains unsafe executable-looking key"
      end
      scan_unsafe_node(child, "#{path}.#{key_text}", errors)
    end
  when Array
    value.each_with_index { |child, index| scan_unsafe_node(child, "#{path}[#{index}]", errors) }
  when String
    if value.match?(UNSAFE_VALUE_RE)
      errors << "#{path} contains unsafe executable-looking string"
    end
  end
end

def ref_namespace(ref)
  return nil unless ref.include?(":")

  ref.split(":", 2).first
end

def ref_name(ref)
  return ref unless ref.include?(":")

  ref.split(":", 2).last
end

def imported_ref?(ref, import_namespaces)
  namespace = ref_namespace(ref)
  namespace && import_namespaces.include?(namespace)
end

def local_ref?(ref, local_names, package_namespace)
  namespace = ref_namespace(ref)
  name = ref_name(ref)
  if namespace
    namespace == package_namespace && local_names.include?(name)
  else
    local_names.include?(name)
  end
end

def resolve_ref?(ref, local_names, package_namespace, import_namespaces)
  scalar_string?(ref) &&
    ref.match?(CONCEPT_RE) &&
    (imported_ref?(ref, import_namespaces) || local_ref?(ref, local_names, package_namespace))
end

def validate_required_top_level(data, errors)
  return nil unless require_hash(data, "package", errors)

  unknown_keys(data, %w[apiVersion kind metadata spec], "package", errors)
  require_key(data, "apiVersion", "package", errors)
  require_key(data, "kind", "package", errors)
  require_key(data, "metadata", "package", errors)
  require_key(data, "spec", "package", errors)

  errors << "apiVersion must be #{API_VERSION}" if data["apiVersion"] && data["apiVersion"] != API_VERSION
  errors << "kind must be #{KIND}" if data["kind"] && data["kind"] != KIND
  data
end

def validate_metadata(metadata, errors)
  return [nil, nil] unless require_hash(metadata, "metadata", errors)

  unknown_keys(metadata, %w[id namespace version publisher source approvalStatus], "metadata", errors)
  id = require_key(metadata, "id", "metadata", errors)
  namespace = require_key(metadata, "namespace", "metadata", errors)
  version = require_key(metadata, "version", "metadata", errors)

  check_pattern(id, ID_RE, "metadata.id", errors)
  check_pattern(namespace, NAMESPACE_RE, "metadata.namespace", errors)
  check_pattern(version, VERSION_RE, "metadata.version", errors)

  [namespace, version]
end

def validate_imports(imports, errors)
  imports = require_array(imports, "spec.imports", errors)
  return Set.new unless imports

  errors << "spec.imports must contain at least one import" if imports.empty?

  namespaces = Set.new
  imports.each_with_index do |entry, index|
    path = "spec.imports[#{index}]"
    next unless require_hash(entry, path, errors)

    unknown_keys(entry, %w[id namespace version], path, errors)
    require_string(require_key(entry, "id", path, errors), "#{path}.id", errors)
    require_string(require_key(entry, "version", path, errors), "#{path}.version", errors)
    namespace = entry["namespace"]
    next unless namespace

    require_string(namespace, "#{path}.namespace", errors)
    namespaces.add(namespace)
  end
  namespaces
end

def validate_classes(classes, state_machine_names, package_namespace, import_namespaces, errors)
  classes = require_hash(classes, "spec.classes", errors)
  return [Set.new, Set.new, Set.new] unless classes

  errors << "spec.classes must contain at least one class" if classes.empty?
  class_names = Set.new(classes.keys)
  command_names = Set.new
  event_names = Set.new

  classes.each do |name, definition|
    path = "spec.classes.#{name}"
    check_pattern(name, NAME_RE, path, errors)
    next unless require_hash(definition, path, errors)

    unknown_keys(definition, %w[extends implements description central lifecycle aliases], path, errors)
    extends = require_key(definition, "extends", path, errors)
    if !extends.is_a?(String)
      errors << "#{path}.extends must be scalar string (multiple inheritance is not allowed)"
    elsif !resolve_ref?(extends, class_names, package_namespace, import_namespaces)
      errors << "#{path}.extends has unknown class reference #{extends}"
    end

    description = require_key(definition, "description", path, errors)
    require_string(description, "#{path}.description", errors)

    implements = definition.key?("implements") ? require_array(definition["implements"], "#{path}.implements", errors) : []
    Array(implements).each_with_index do |ref, index|
      unless scalar_string?(ref) && ref.match?(CONCEPT_RE) &&
             (imported_ref?(ref, import_namespaces) || local_ref?(ref, class_names, package_namespace))
        errors << "#{path}.implements[#{index}] has unknown protocol/class reference #{ref.inspect}"
      end
    end

    lifecycle = definition["lifecycle"]
    if lifecycle && !state_machine_names.include?(lifecycle)
      errors << "#{path}.lifecycle references unknown state machine #{lifecycle}"
    end

    command_names.add(name) if extends == "sg:Command" || extends == "Command"
    event_names.add(name) if extends == "sg:Event" || extends == "Event"
  end

  [class_names, command_names, event_names]
end

def range_refs(range)
  if range.is_a?(String)
    [range]
  elsif range.is_a?(Hash) && range["oneOf"].is_a?(Array)
    range["oneOf"]
  else
    []
  end
end

def validate_relations(relations, class_names, package_namespace, import_namespaces, errors)
  relations = require_hash(relations, "spec.relations", errors)
  return Set.new unless relations

  errors << "spec.relations must contain at least one relation" if relations.empty?
  relation_names = Set.new(relations.keys)

  relations.each do |name, definition|
    path = "spec.relations.#{name}"
    check_pattern(name, NAME_RE, path, errors)
    next unless require_hash(definition, path, errors)

    unknown_keys(definition, %w[domain range cardinality description], path, errors)
    domain = require_key(definition, "domain", path, errors)
    unless resolve_ref?(domain, class_names, package_namespace, import_namespaces)
      errors << "#{path}.domain has unknown relation domain reference #{domain.inspect}"
    end

    range = require_key(definition, "range", path, errors)
    refs = range_refs(range)
    errors << "#{path}.range must be a reference string or oneOf reference list" if refs.empty?
    refs.each_with_index do |ref, index|
      next if resolve_ref?(ref, class_names, package_namespace, import_namespaces)

      errors << "#{path}.range[#{index}] has unknown relation range reference #{ref.inspect}"
    end
  end

  relation_names
end

def validate_policies(policies, class_names, package_namespace, import_namespaces, errors)
  policies = require_hash(policies, "spec.policies", errors)
  return Set.new unless policies

  errors << "spec.policies must contain at least one policy" if policies.empty?
  policy_names = Set.new(policies.keys)
  allowed_enforceability = Set.new(%w[design runtime manual audit])

  policies.each do |name, definition|
    path = "spec.policies.#{name}"
    check_pattern(name, NAME_RE, path, errors)
    next unless require_hash(definition, path, errors)

    unknown_keys(definition, %w[extends enforceability appliesTo text], path, errors)
    extends = require_key(definition, "extends", path, errors)
    unless scalar_string?(extends) && extends.match?(CONCEPT_RE) &&
           (imported_ref?(extends, import_namespaces) || local_ref?(extends, policy_names, package_namespace))
      errors << "#{path}.extends has unknown policy reference #{extends.inspect}"
    end

    enforceability = require_key(definition, "enforceability", path, errors)
    unless allowed_enforceability.include?(enforceability)
      errors << "#{path}.enforceability must be one of #{allowed_enforceability.to_a.sort.join(', ')}"
    end

    applies_to = require_array(require_key(definition, "appliesTo", path, errors), "#{path}.appliesTo", errors)
    if applies_to && applies_to.empty?
      errors << "#{path}.appliesTo must contain at least one target"
    end
    Array(applies_to).each_with_index do |ref, index|
      next if resolve_ref?(ref, class_names, package_namespace, import_namespaces)

      errors << "#{path}.appliesTo[#{index}] has unknown policy target reference #{ref.inspect}"
    end

    require_string(require_key(definition, "text", path, errors), "#{path}.text", errors)
  end

  policy_names
end

def validate_state_machines(state_machines, command_names, event_names, package_namespace, errors)
  state_machines = require_hash(state_machines, "spec.stateMachines", errors)
  return Set.new unless state_machines

  errors << "spec.stateMachines must contain at least one state machine" if state_machines.empty?
  names = Set.new(state_machines.keys)

  state_machines.each do |name, definition|
    path = "spec.stateMachines.#{name}"
    check_pattern(name, NAME_RE, path, errors)
    next unless require_hash(definition, path, errors)

    unknown_keys(definition, %w[states transitions], path, errors)
    states = require_array(require_key(definition, "states", path, errors), "#{path}.states", errors)
    state_set = Set.new(Array(states))
    errors << "#{path}.states must contain at least one state" if state_set.empty?
    Array(states).each_with_index { |state, index| check_pattern(state, STATE_RE, "#{path}.states[#{index}]", errors) }

    transitions = require_array(require_key(definition, "transitions", path, errors), "#{path}.transitions", errors)
    errors << "#{path}.transitions must contain at least one transition" if Array(transitions).empty?
    Array(transitions).each_with_index do |transition, index|
      tpath = "#{path}.transitions[#{index}]"
      next unless require_hash(transition, tpath, errors)

      unknown_keys(transition, %w[from to command event], tpath, errors)
      from = require_key(transition, "from", tpath, errors)
      to = require_key(transition, "to", tpath, errors)
      errors << "#{tpath}.from references unknown state #{from.inspect}" unless state_set.include?(from)
      errors << "#{tpath}.to references unknown state #{to.inspect}" unless state_set.include?(to)

      command = transition["command"]
      if command
        command_name = ref_name(command)
        valid_local_command = (ref_namespace(command).nil? || ref_namespace(command) == package_namespace) &&
                              command_names.include?(command_name)
        errors << "#{tpath}.command references unknown command #{command.inspect}" unless valid_local_command
      end

      event = transition["event"]
      next unless event

      event_name = ref_name(event)
      valid_local_event = (ref_namespace(event).nil? || ref_namespace(event) == package_namespace) &&
                          event_names.include?(event_name)
      errors << "#{tpath}.event references unknown event #{event.inspect}" unless valid_local_event
    end
  end

  names
end

def validate_package(data, load_errors)
  errors = load_errors.dup
  return errors unless validate_required_top_level(data, errors)

  scan_unsafe_node(data, "package", errors)
  package_namespace, = validate_metadata(data["metadata"], errors)
  spec = require_hash(data["spec"], "spec", errors)
  return errors unless spec

  unknown_keys(spec, %w[imports classes protocols relations policies stateMachines compatibility], "spec", errors)
  %w[imports classes relations policies stateMachines].each do |key|
    require_key(spec, key, "spec", errors)
  end

  import_namespaces = validate_imports(spec["imports"], errors)
  state_machine_names = spec["stateMachines"].is_a?(Hash) ? Set.new(spec["stateMachines"].keys) : Set.new
  class_names, command_names, event_names = validate_classes(
    spec["classes"],
    state_machine_names,
    package_namespace,
    import_namespaces,
    errors
  )
  validate_relations(spec["relations"], class_names, package_namespace, import_namespaces, errors)
  validate_policies(spec["policies"], class_names, package_namespace, import_namespaces, errors)
  validate_state_machines(spec["stateMachines"], command_names, event_names, package_namespace, errors)

  errors
end

def check_fixture(path, expected, expected_error = nil)
  data, load_errors = safe_load_yaml(path)
  errors = validate_package(data, load_errors)
  valid = errors.empty?

  if expected == :valid && valid
    puts "PASS valid   #{rel(path)}"
    return true
  end

  if expected == :invalid && !valid && errors.any? { |error| error.match?(expected_error) }
    puts "PASS invalid #{rel(path)}"
    return true
  end

  puts "FAIL #{expected.to_s.ljust(7)} #{rel(path)}"
  errors.each { |error| puts "  - #{error}" }
  false
end

passed = 0
failed = 0

VALID_FIXTURES.each do |path|
  check_fixture(path, :valid) ? passed += 1 : failed += 1
end

INVALID_FIXTURES.sort.each do |path, expectation|
  check_fixture(path, :invalid, expectation) ? passed += 1 : failed += 1
end

puts "Validated #{passed + failed} fixtures: #{passed} passed, #{failed} failed"
exit(failed.zero? ? 0 : 1)
