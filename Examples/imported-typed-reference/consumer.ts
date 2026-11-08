import type { Use } from './generated/types';
import { UseSchema } from './generated/schemas';

const valid: Use = { $type: 'draft:Use', target: { target: 'canonical:Item', locator: 'item-1' } };
const wrong: Use = { $type: 'draft:Use', target: {
  // @ts-expect-error An item from the local package is a different type.
  target: 'draft:Item', locator: 'item-1',
} };
if (!UseSchema.safeParse(valid).success || UseSchema.safeParse(wrong).success) {
  throw new Error('Imported target identity was not enforced');
}
console.log('Imported Ref passes TypeScript and Zod identity checks');
