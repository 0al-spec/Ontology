#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "yaml"

ROOT = __dir__
MANIFEST_PATH = File.join(ROOT, "validation-manifest.yaml")

def safe_load_file(path)
  YAML.safe_load(
    File.read(path),
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false
  )
end

def safe_load_documents(path)
  File.read(path)
      .split(/^---\s*$/)
      .map(&:strip)
      .reject(&:empty?)
      .map do |document|
        YAML.safe_load(
          document,
          permitted_classes: [],
          permitted_symbols: [],
          aliases: false
        )
      end
end

def collect_examcalc_refs(value, refs)
  case value
  when Hash
    value.each_value { |child| collect_examcalc_refs(child, refs) }
  when Array
    value.each { |child| collect_examcalc_refs(child, refs) }
  when String
    refs.add(value) if value.start_with?("examcalc:")
  end
end

def missing(required, actual)
  Array(required).reject { |item| actual.include?(item) }
end

def transition_key(transition)
  [
    transition["from"],
    transition["to"],
    transition["command"],
    transition["event"]
  ]
end

errors = []
manifest = safe_load_file(MANIFEST_PATH)
manifest_spec = manifest.fetch("spec")
metadata = manifest.fetch("metadata")
namespace = metadata.fetch("namespace")

package_path = File.join(ROOT, manifest_spec.fetch("package"))
package = safe_load_file(package_path)
package_metadata = package.fetch("metadata")
package_spec = package.fetch("spec")

if package_metadata["id"] != metadata["ontology"]
  errors << "package metadata.id #{package_metadata['id'].inspect} does not match manifest ontology #{metadata['ontology'].inspect}"
end

if package_metadata["namespace"] != namespace
  errors << "package metadata.namespace #{package_metadata['namespace'].inspect} does not match manifest namespace #{namespace.inspect}"
end

if package_metadata["version"] != metadata["version"]
  errors << "package metadata.version #{package_metadata['version'].inspect} does not match manifest version #{metadata['version'].inspect}"
end

classes = package_spec.fetch("classes")
relations = package_spec.fetch("relations")
policies = package_spec.fetch("policies")
state_machines = package_spec.fetch("stateMachines")

class_names = Set.new(classes.keys)
relation_names = Set.new(relations.keys)
policy_names = Set.new(policies.keys)
resolvable_symbols = class_names + relation_names + policy_names + Set.new(state_machines.keys)

missing_classes = missing(manifest_spec["requiredClasses"], class_names)
errors << "missing required classes: #{missing_classes.join(', ')}" unless missing_classes.empty?

missing_audit_classes = missing(manifest_spec["auditClasses"], class_names)
errors << "missing audit classes: #{missing_audit_classes.join(', ')}" unless missing_audit_classes.empty?

missing_relations = missing(manifest_spec["requiredRelations"], relation_names)
errors << "missing required relations: #{missing_relations.join(', ')}" unless missing_relations.empty?

missing_policies = missing(manifest_spec["requiredPolicies"], policy_names)
errors << "missing required policies: #{missing_policies.join(', ')}" unless missing_policies.empty?

manifest_spec.fetch("policyExpectations").each do |policy_name, expected|
  policy = policies[policy_name]
  next errors << "policy expectation references missing policy #{policy_name}" unless policy

  if policy["enforceability"] != expected["enforceability"]
    errors << "#{policy_name}.enforceability expected #{expected['enforceability']} got #{policy['enforceability']}"
  end

  missing_targets = missing(expected["appliesTo"], Set.new(policy.fetch("appliesTo", [])))
  next if missing_targets.empty?

  errors << "#{policy_name}.appliesTo missing #{missing_targets.join(', ')}"
end

manifest_spec.fetch("stateMachines").each do |machine_name, expected|
  machine = state_machines[machine_name]
  next errors << "missing state machine #{machine_name}" unless machine

  actual_states = Set.new(machine.fetch("states", []))
  missing_states = missing(expected["states"], actual_states)
  errors << "#{machine_name} missing states: #{missing_states.join(', ')}" unless missing_states.empty?

  actual_transitions = Set.new(machine.fetch("transitions", []).map { |transition| transition_key(transition) })
  expected.fetch("transitions").each do |transition|
    key = transition_key(transition)
    next if actual_transitions.include?(key)

    errors << "#{machine_name} missing transition #{transition.inspect}"
  end
end

binding_refs = Set.new
manifest_spec.fetch("bindings").sort.each do |binding_file|
  safe_load_documents(File.join(ROOT, binding_file)).each do |document|
    collect_examcalc_refs(document, binding_refs)
  end
end

unresolved_refs = binding_refs.reject do |ref|
  ref_namespace, symbol = ref.split(":", 2)
  ref_namespace == namespace && resolvable_symbols.include?(symbol)
end
errors << "unresolved semantic refs: #{unresolved_refs.sort.join(', ')}" unless unresolved_refs.empty?

missing_semantic_refs = missing(manifest_spec["requiredSemanticRefs"], binding_refs)
errors << "binding missing required semantic refs: #{missing_semantic_refs.join(', ')}" unless missing_semantic_refs.empty?

if errors.empty?
  puts "PASS package metadata #{package_metadata['id']}@#{package_metadata['version']}"
  puts "PASS classes #{manifest_spec['requiredClasses'].length}/#{manifest_spec['requiredClasses'].length}"
  puts "PASS audit concepts #{manifest_spec['auditClasses'].length}/#{manifest_spec['auditClasses'].length}"
  puts "PASS relations #{manifest_spec['requiredRelations'].length}/#{manifest_spec['requiredRelations'].length}"
  puts "PASS policies #{manifest_spec['requiredPolicies'].length}/#{manifest_spec['requiredPolicies'].length}"
  puts "PASS state machine ExamModeSessionState"
  puts "PASS semantic refs #{binding_refs.length}/#{binding_refs.length} resolved"
  puts "Validated examcalc golden package: PASS"
  exit 0
end

puts "Validated examcalc golden package: FAIL"
errors.each { |error| puts "  - #{error}" }
exit 1
