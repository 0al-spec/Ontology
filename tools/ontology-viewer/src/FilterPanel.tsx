import { useId } from 'react';
import { edgeKindOptions, nodeTypeOptions, originOptions, type GraphFilters } from './filters';

export function FilterPanel({ filters, onChange, onReset }: {
  filters: GraphFilters;
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
    <p>Filter the loaded graph without moving nodes.</p>
    <fieldset><legend>Node types</legend>
      {nodeTypeOptions.map(([key, label]) => <label key={key}>
        <input type="checkbox" checked={filters.nodeTypes[key]} onChange={(event) =>
          onChange({ ...filters, nodeTypes: { ...filters.nodeTypes, [key]: event.target.checked } })} /> {label}
      </label>)}
    </fieldset>
    <fieldset><legend>Origin</legend>
      {originOptions.map(([key, label]) => <label key={key}>
        <input type="checkbox" checked={filters.origins[key]} onChange={(event) =>
          onChange({ ...filters, origins: { ...filters.origins, [key]: event.target.checked } })} /> {label}
      </label>)}
    </fieldset>
    <fieldset><legend>Relationships</legend>
      {edgeKindOptions.map(([key, label]) => <label key={key}>
        <input type="checkbox" checked={filters.edgeKinds[key]} onChange={(event) =>
          onChange({ ...filters, edgeKinds: { ...filters.edgeKinds, [key]: event.target.checked } })} /> {label}
      </label>)}
    </fieldset>
    <button type="button" onClick={onReset}>Reset filters</button>
    </div>
  </details>;
}
