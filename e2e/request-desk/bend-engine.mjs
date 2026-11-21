import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

const states = new Map([
  ['idle', 'Idle'],
  ['pending', 'Pending'],
  ['responded', 'Responded'],
]);
const commands = new Map([
  ['submit', 'Accept'],
  ['retry', 'Retry'],
  ['respond', 'Respond'],
]);
const labels = new Map([...states].map(([label, tag]) => [tag, label]));

function constructor(mapping, label) {
  const tag = mapping.get(label);
  if (!tag) throw new RangeError(`Unknown request-desk input: ${String(label)}`);
  return {$: tag};
}

// This adapter only translates tags; Bend decides transitions and keeps state on denial.
export async function createEngine(compiledModulePath) {
  const {default: machine} = await import(pathToFileURL(resolve(compiledModulePath)).href);
  if (typeof machine?.step !== 'function' || typeof machine?.state_after !== 'function') {
    throw new TypeError('Expected a compiled request-desk Bend module');
  }
  return {
    step(state, command) {
      const current = constructor(states, state);
      const event = constructor(commands, command);
      const next = machine.state_after(current, machine.step(current, event));
      const label = labels.get(next?.$);
      if (!label) throw new TypeError('Compiled Bend returned an unknown state');
      return label;
    },
  };
}
