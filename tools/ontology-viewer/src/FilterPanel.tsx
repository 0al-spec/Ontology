import { useId } from 'react';
import { edgeKindOptions, nodeTypeOptions, originOptions, type FilterCounts, type GraphFilters } from './filters';

export function FilterPanel({ filters, onChange, onReset, counts, view }: {
  filters: GraphFilters;
  counts?: FilterCounts;
  view?: string;
  onChange: (next: GraphFilters) => void;
  onReset: () => void;
}) {
  const modeGroup = useId();
  const disabled = [...Object.values(filters.nodeTypes), ...Object.values(filters.origins), ...Object.values(filters.edgeKinds)]
    .filter((enabled) => !enabled).length;
  return <details className="filter-panel">
    <summary>Filters {disabled > 0 && <span>{disabled} off</span>}</summary>
    <fieldset className="filter-mode"><legend>Filtered elements</legend>
      <label><input type="radio" name={modeGroup} checked={filters.mode === 'hide'}
        onChange={() => onChange({ ...filters, mode: 'hide' })} /> Hide</label>
      <label><input type="radio" name={modeGroup} checked={filters.mode === 'dim'}
        onChange={() => onChange({ ...filters, mode: 'dim' })} /> Dim</label>
    </fieldset>
    <div className="filter-body">
    <p>Node counts include unloaded references. Relationships count visual links.</p>
    {view === 'relations' && <p>Relations view includes classes and ontology relations only. Use a full profile for other categories.</p>}
    <fieldset><legend>Node types</legend>
      {nodeTypeOptions.map(([key, label]) => <label key={key}>
        <input type="checkbox" aria-description={counts ? `${counts.nodeTypes[key]} in the loaded graph` : undefined} checked={filters.nodeTypes[key]} onChange={(event) =>
          onChange({ ...filters, nodeTypes: { ...filters.nodeTypes, [key]: event.target.checked } })} /> {label} {counts && <span className="filter-count" aria-hidden="true" data-testid={`filter-count-type-${key}`}>{counts.nodeTypes[key]}</span>}
      </label>)}
    </fieldset>
    <fieldset><legend>Origin</legend>
      {originOptions.map(([key, label]) => <label key={key}>
        <input type="checkbox" aria-description={counts ? `${counts.origins[key]} in the loaded graph` : undefined} checked={filters.origins[key]} onChange={(event) =>
          onChange({ ...filters, origins: { ...filters.origins, [key]: event.target.checked } })} /> {label} {counts && <span className="filter-count" aria-hidden="true" data-testid={`filter-count-origin-${key}`}>{counts.origins[key]}</span>}
      </label>)}
    </fieldset>
    <fieldset><legend>Relationships</legend>
      {edgeKindOptions.map(([key, label]) => <label key={key}>
        <input type="checkbox" aria-description={counts ? `${counts.edgeKinds[key]} in the loaded graph` : undefined} checked={filters.edgeKinds[key]} onChange={(event) =>
          onChange({ ...filters, edgeKinds: { ...filters.edgeKinds, [key]: event.target.checked } })} /> {label} {counts && <span className="filter-count" aria-hidden="true" data-testid={`filter-count-edge-${key}`}>{counts.edgeKinds[key]}</span>}
      </label>)}
    </fieldset>
    <button type="button" onClick={onReset}>Reset filters</button>
    </div>
  </details>;
}
