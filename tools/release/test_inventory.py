"""Inventory uses evaluated product identities rather than Swift source paths."""
import unittest

import inventory


class InventoryTests(unittest.TestCase):
    def package(self, names):
        return {"products": [
            *[{"name": name, "type": {"executable": None}} for name in names],
            {"name": "OntologyCompiler", "type": {"library": ["automatic"]}}
        ]}

    def test_compiler_only_release_manifest(self):
        self.assertEqual(inventory.executable_inventory(self.package(["ontologyc"])), "ontologyc")

    def test_two_products_independent_of_entrypoint_path_or_computed_name(self):
        # SwiftPM evaluates names and @main entrypoint layout before this parser.
        self.assertEqual(inventory.executable_inventory(self.package(["ontologyviz", "ontologyc"])),
                         "ontologyc,ontologyviz")

    def test_missing_or_ambiguous_products_fail(self):
        for names in [[], ["ontologyviz"], ["ontologyc", "ontologyc"],
                      ["ontologyc", "ontologyviz", "ontologyviz"], ["ontologyc", "unknown"]]:
            with self.subTest(names=names), self.assertRaises(ValueError):
                inventory.executable_inventory(self.package(names))
        with self.assertRaises(KeyError):
            inventory.executable_inventory({})
