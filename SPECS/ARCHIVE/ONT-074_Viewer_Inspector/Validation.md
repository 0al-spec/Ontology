# ONT-074 validation

The original Viewer on the ONT-073 example exposed Domain and Range, with
action and field target in the raw declaration. A baseline Chromium check
confirmed the action could not be opened from the inspector.

The revised build passed TypeScript, 17 Vitest tests and all 22 repository
Playwright scenarios, including four new inspector cases. Two additional local
browser checks passed on actual compiler exports. One followed the membership
relation through AddRepository to Repository with the raw panel collapsed. The
other used a local action subclass with two independently named fields pointing
to the same class. Keyboard navigation preserved active filters and selected the
correct declaration. These checks used the compiler and visualizer from ONT-073.
